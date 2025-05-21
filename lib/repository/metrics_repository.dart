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
  $openedQuery: String!,
  $mergedQuery: String!,
  $langCount: Int!
) {
  repository(owner: $owner, name: $name) {
    defaultBranchRef {
      target {
        ... on Commit {
          dayHistory: history(since: $since, first: 100) {
            nodes {
              additions
              deletions
            }
          }
          latestCommits: history(first: 1) {
            nodes {
              oid
              message
              committedDate
              author { name }
            }
          }
        }
      }
    }
    languages(first: $langCount, orderBy: {field: SIZE, direction: DESC}) {
      totalSize
      edges {
        size
        node { name color }
      }
    }
    refs(refPrefix: "refs/heads/") {
      totalCount
    }
    stargazerCount
  }
  prOpened: search(query: $openedQuery, type: ISSUE) { issueCount }
  prMerged: search(query: $mergedQuery, type: ISSUE) { issueCount }
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
    final localMidnight = DateTime(now.year, now.month, now.day);
    final sinceIso = localMidnight.toUtc().toIso8601String();

    final openedQuery = 'repo:$owner/$name is:pr is:open created:>$sinceIso';
    final mergedQuery = 'repo:$owner/$name is:pr is:merged merged:>$sinceIso';

    final result = await service.query(
      _fetchMetricsQuery,
      variables: {
        'owner': owner,
        'name': name,
        'since': sinceIso,
        'openedQuery': openedQuery,
        'mergedQuery': mergedQuery,
        'langCount': 10,
      },
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final repo = result.data!['repository'];
    final commitTarget = repo['defaultBranchRef']['target'];

    // 1) Lines added/deleted
    final dayNodes = commitTarget['dayHistory']['nodes'] as List<dynamic>;
    var added = 0, deleted = 0;
    for (final n in dayNodes) {
      added += n['additions'] as int;
      deleted += n['deletions'] as int;
    }

    // 2) Latest commit (title only)
    final latestNodes = commitTarget['latestCommits']['nodes'] as List<dynamic>;
    final ln = latestNodes.first;
    final author = (ln['author']?['name'] as String?) ?? 'unknown';
    // only first line of the commit message:
    final fullMsg = ln['message'] as String;
    final title = fullMsg.split('\n').first;
    final oid = (ln['oid'] as String).substring(0, 7);
    final committed = DateTime.parse(ln['committedDate'] as String).toLocal();
    final minutesAgo = now.difference(committed).inMinutes;
    final latestCommit = LatestCommit(
      author: author,
      message: title, // store just the title
      id: oid,
      minutesAgo: minutesAgo,
    );

    // 3) Languages
    final langs = repo['languages'];
    final totalSize = langs['totalSize'] as int;
    final languages = <LanguageStat>[];
    for (final edge in langs['edges']) {
      final size = edge['size'] as int;
      final node = edge['node'];
      languages.add(
        LanguageStat(
          name: node['name'] as String,
          colorHex: node['color'] as String? ?? '#CCCCCC',
          percentage: totalSize > 0 ? size / totalSize : 0,
        ),
      );
    }

    // 4) Branches & stars
    final branchCount = repo['refs']['totalCount'] as int;
    final starCount = repo['stargazerCount'] as int;

    // 5) PR counts
    final prOpened = result.data!['prOpened']['issueCount'] as int;
    final prMerged = result.data!['prMerged']['issueCount'] as int;

    return Metrics(
      linesAdded: added,
      linesDeleted: deleted,
      languages: languages,
      prOpened: prOpened,
      prMerged: prMerged,
      branchCount: branchCount,
      starCount: starCount,
      latestCommit: latestCommit,
    );
  }
}
