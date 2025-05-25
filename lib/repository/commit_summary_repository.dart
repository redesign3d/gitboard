import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/commit_summary.dart';

class CommitSummaryRepository {
  final GraphQLClient _gqlClient;
  final String _token;
  final String _owner;
  final String _repo;

  CommitSummaryRepository({
    required GraphQLClient gqlClient,
    required String token,
    required String owner,
    required String repo,
  })  : _gqlClient = gqlClient,
        _token = token,
        _owner = owner,
        _repo = repo;

  Future<CommitSummary> fetchSummary() async {
    final since = DateTime.now()
        .subtract(const Duration(days: 28))
        .toUtc()
        .toIso8601String();

    // 1) REST PushEvent → commits & authors
    final eventsUrl = Uri.parse(
      'https://api.github.com/repos/$_owner/$_repo/events?per_page=100',
    );
    final eventsRes = await http.get(
      eventsUrl,
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );
    if (eventsRes.statusCode != 200) {
      throw Exception('Failed to load events: ${eventsRes.statusCode}');
    }
    final rawEvents = json.decode(eventsRes.body) as List<dynamic>;
    final cutoff = DateTime.parse(since).toLocal();
    final pushEvents = rawEvents.where((e) {
      if (e['type'] != 'PushEvent') return false;
      final created =
          DateTime.parse(e['created_at'] as String).toLocal();
      return created.isAfter(cutoff);
    }).toList();

    final allCommits = <Map<String, dynamic>>[];
    for (var pe in pushEvents) {
      final commits = (pe['payload']['commits'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (var c in commits) {
        final msg = c['message'] as String;
        if (!msg.startsWith('Merge pull request')) {
          allCommits.add(c);
        }
      }
    }
    final commitsCount = allCommits.length;
    final authorsCount = allCommits
        .map((c) => (c['author']?['email'] as String?) ?? '')
        .toSet()
        .length;

    // 2) GraphQL history → files/adds/dels on default branch
    const _gqlQuery = r'''
query CommitHistory($owner: String!, $name: String!, $since: GitTimestamp!) {
  repository(owner: $owner, name: $name) {
    defaultBranchRef {
      target {
        ... on Commit {
          history(since: $since, first: 100) {
            nodes {
              changedFiles
              additions
              deletions
              committedDate
            }
          }
        }
      }
    }
  }
}
''';

    final result = await _gqlClient.query(
      QueryOptions(
        document: gql(_gqlQuery),
        variables: {
          'owner': _owner,
          'name': _repo,
          'since': since,
        },
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final nodes = (result.data!['repository']
            ['defaultBranchRef']['target']['history']['nodes']
        as List<dynamic>);
    var changedFiles = 0, additions = 0, deletions = 0;
    final cutoffLocal = DateTime.parse(since).toLocal();
    for (var n in nodes) {
      final dt = DateTime.parse(n['committedDate'] as String).toLocal();
      if (dt.isAfter(cutoffLocal)) {
        changedFiles += n['changedFiles'] as int;
        additions += n['additions'] as int;
        deletions += n['deletions'] as int;
      }
    }

    return CommitSummary(
      authorsCount: authorsCount,
      commitsCount: commitsCount,
      changedFiles: changedFiles,
      additions: additions,
      deletions: deletions,
    );
  }
}
