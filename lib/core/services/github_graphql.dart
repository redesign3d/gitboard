import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GithubGraphQL {
  final GraphQLClient _client;

  GithubGraphQL()
      : _client = GraphQLClient(
          link: HttpLink(
            'https://api.github.com/graphql',
            defaultHeaders: {
              'Authorization': 'Bearer ${dotenv.env['GITHUB_TOKEN']}'
            },
          ),
          cache: GraphQLCache(store: InMemoryStore()),
        );

  static const String _intradayMetricsQuery = r'''
query IntradayMetrics(
  $owner: String!,
  $name: String!,
  $since: GitTimestamp!,       # changed from DateTime!
  $issuesOpenedQuery: String!,
  $issuesClosedQuery: String!,
  $prsOpenedQuery: String!,
  $prsMergedQuery: String!
) {
  repository(owner: $owner, name: $name) {
    defaultBranchRef {
      target {
        ... on Commit {
          history(since: $since) {
            totalCount
            nodes {
              additions
              deletions
              author {
                user { login }
              }
            }
          }
        }
      }
    }
    stargazerCount
    forkCount
    watchers { totalCount }
    languages(first: 10, orderBy: { field: SIZE, direction: DESC }) {
      edges {
        size
        node { name }
      }
    }
  }
  issuesOpened: search(query: $issuesOpenedQuery, type: ISSUE) {
    issueCount
  }
  issuesClosed: search(query: $issuesClosedQuery, type: ISSUE) {
    issueCount
  }
  prsOpened: search(query: $prsOpenedQuery, type: ISSUE) {
    issueCount
  }
  prsMerged: search(query: $prsMergedQuery, type: ISSUE) {
    issueCount
  }
}
''';

  /// Fetches intraday metrics by combining Commit history + Search counts.
  Future<QueryResult> fetchIntradayMetrics({
    required String owner,
    required String name,
    required DateTime sinceUtc, // pass in UTC midnight
  }) {
    final isoDate = sinceUtc.toIso8601String().substring(0, 10);
    final repoQualifier = 'repo:$owner/$name';
    final vars = {
      'owner': owner,
      'name': name,
      'since': sinceUtc.toUtc().toIso8601String(),
      'issuesOpenedQuery': '$repoQualifier is:issue created:>=$isoDate',
      'issuesClosedQuery': '$repoQualifier is:issue is:closed closed:>=$isoDate',
      'prsOpenedQuery': '$repoQualifier is:pr created:>=$isoDate',
      'prsMergedQuery': '$repoQualifier is:pr is:merged merged:>=$isoDate',
    };

    return _client.query(
      QueryOptions(
        document: gql(_intradayMetricsQuery),
        variables: vars,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
  }
}
