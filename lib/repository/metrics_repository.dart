import 'package:intl/intl.dart';

import '../models/metrics.dart';
import '../models/language_stat.dart';
import '../services/graphql_service.dart';

class MetricsRepository {
  static const _fetchMetricsQuery = r'''
query FetchMetrics($owner: String!, $name: String!, $since: GitTimestamp!, $langCount: Int!) {
  repository(owner: $owner, name: $name) {
    defaultBranchRef {
      target {
        ... on Commit {
          history(since: $since, first: 100) {
            nodes {
              additions
              deletions
            }
          }
        }
      }
    }
    languages(first: $langCount, orderBy: {field: SIZE, direction: DESC}) {
      totalSize
      edges {
        size
        node {
          name
          color
        }
      }
    }
  }
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
    final midnight = DateTime.now()
        .toLocal()
        .subtract(Duration(
          hours: DateTime.now().hour,
          minutes: DateTime.now().minute,
          seconds: DateTime.now().second,
          milliseconds: DateTime.now().millisecond,
          microseconds: DateTime.now().microsecond,
        ))
        .toUtc()
        .toIso8601String();

    final result = await service.query(
      _fetchMetricsQuery,
      variables: {
        'owner': owner,
        'name': name,
        'since': midnight,
        'langCount': 10,
      },
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final repo = result.data!['repository'];
    // Lines added/deleted
    final history = repo['defaultBranchRef']?['target']?['history'];
    int added = 0, deleted = 0;
    if (history != null && history['nodes'] != null) {
      for (final node in history['nodes']) {
        added += node['additions'] as int;
        deleted += node['deletions'] as int;
      }
    }

    // Language breakdown
    final langs = repo['languages'];
    final totalSize = langs['totalSize'] as int;
    final List<LanguageStat> languages = [];
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

    return Metrics(
      linesAdded: added,
      linesDeleted: deleted,
      languages: languages,
    );
  }
}
