// lib/repository/metrics_repository.dart
import '../models/metrics.dart';
import '../models/language_stat.dart';
import '../models/latest_commit.dart';
import '../services/graphql_service.dart';

class MetricsRepository {
  static const _fetchMetricsQuery = r'''
query FetchMetrics(
  $owner: String!,
  $name: String!,
  $since: GitTimestamp!,
  $prOpenedQuery: String!,
  $prMergedQuery: String!,
  $issueOpenedQuery: String!,
  $issueClosedQuery: String!,
  $issueReopenedQuery: String!,
  $langCount: Int!
) {
  repository(owner: $owner, name: $name) {
    defaultBranchRef {
      target {
        ... on Commit {
          dayHistory: history(since: $since, first: 100) {
            nodes { additions deletions }
          }
          latestCommits: history(first: 1) {
            nodes { oid message committedDate author { name } }
          }
        }
      }
    }
    languages(first: $langCount, orderBy: {field: SIZE, direction: DESC}) {
      totalSize
      edges { size node { name color } }
    }
    refs(refPrefix: "refs/heads/") { totalCount }
    stargazerCount
  }
  prOpened: search(query: $prOpenedQuery, type: ISSUE) { issueCount }
  prMerged: search(query: $prMergedQuery, type: ISSUE) { issueCount }
  issueOpened: search(query: $issueOpenedQuery, type: ISSUE) { issueCount }
  issueClosed: search(query: $issueClosedQuery, type: ISSUE) { issueCount }
  issueReopened: search(query: $issueReopenedQuery, type: ISSUE) { issueCount }
}
''';

  final GraphQLService service;
  final String owner;
  final String name;

  MetricsRepository({
    required this.service,
    required this.owner,
    required this.name,
  });

  Future<Metrics> fetchMetrics() async {
    final now = DateTime.now();
    final localMid = DateTime(now.year, now.month, now.day);
    final sinceIso = localMid.toUtc().toIso8601String();

    // PR queries
    final prOpenedQuery =
        'repo:$owner/$name is:pr is:open created:>$sinceIso';
    final prMergedQuery =
        'repo:$owner/$name is:pr is:merged merged:>$sinceIso';

    // Issue queries
    final issueOpenedQuery =
        'repo:$owner/$name is:issue is:open created:>$sinceIso';
    final issueClosedQuery =
        'repo:$owner/$name is:issue is:closed closed:>$sinceIso';
    final issueReopenedQuery =
        'repo:$owner/$name is:issue is:reopened updated:>$sinceIso';

    final result = await service.query(
      _fetchMetricsQuery,
      variables: {
        'owner': owner,
        'name': name,
        'since': sinceIso,
        'prOpenedQuery': prOpenedQuery,
        'prMergedQuery': prMergedQuery,
        'issueOpenedQuery': issueOpenedQuery,
        'issueClosedQuery': issueClosedQuery,
        'issueReopenedQuery': issueReopenedQuery,
        'langCount': 10,
      },
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final repo = result.data!['repository'];
    final commitTarget = repo['defaultBranchRef']['target'];

    // Lines added/deleted
    final dayNodes = commitTarget['dayHistory']['nodes'] as List<dynamic>;
    var added = 0, deleted = 0;
    for (final n in dayNodes) {
      added += n['additions'] as int;
      deleted += n['deletions'] as int;
    }

    // Latest commit
    final latestNodes =
        commitTarget['latestCommits']['nodes'] as List<dynamic>;
    final ln = latestNodes.first;
    final oid = (ln['oid'] as String).substring(0, 7);
    final committed =
        DateTime.parse(ln['committedDate'] as String).toLocal();
    final latestCommit = LatestCommit(
      author: (ln['author']?['name'] as String?) ?? 'unknown',
      message: ln['message'].toString().split('\n').first,
      id: oid,
      minutesAgo: now.difference(committed).inMinutes,
    );

    // Languages
    final langs = repo['languages'];
    final totalSize = langs['totalSize'] as int;
    final languages = <LanguageStat>[];
    for (final edge in langs['edges']) {
      final node = edge['node'];
      languages.add(LanguageStat(
        name: node['name'] as String,
        colorHex: node['color'] as String? ?? '#CCCCCC',
        percentage: totalSize > 0
            ? (edge['size'] as int) / totalSize
            : 0,
      ));
    }

    // Branch & stars
    final branchCount = repo['refs']['totalCount'] as int;
    final starCount = repo['stargazerCount'] as int;

    // PR & Issue counts
    final prOpened = result.data!['prOpened']['issueCount'] as int;
    final prMerged = result.data!['prMerged']['issueCount'] as int;
    final issueOpened = result.data!['issueOpened']['issueCount'] as int;
    final issueClosed = result.data!['issueClosed']['issueCount'] as int;
    final issueReopened =
        result.data!['issueReopened']['issueCount'] as int;

    return Metrics(
      linesAdded: added,
      linesDeleted: deleted,
      languages: languages,
      prOpened: prOpened,
      prMerged: prMerged,
      issueOpened: issueOpened,
      issueClosed: issueClosed,
      issueReopened: issueReopened,
      branchCount: branchCount,
      starCount: starCount,
      latestCommit: latestCommit,
    );
  }
}
