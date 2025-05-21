// lib/services/graphql_service.dart
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  final GraphQLClient _client;

  GraphQLService(String token)
      : _client = GraphQLClient(
          link: HttpLink(
            'https://api.github.com/graphql',
            defaultHeaders: {
              'Authorization': 'Bearer $token',
            },
          ),
          cache: GraphQLCache(), // uses HiveStore under the hood
        ) {
    print('[DEBUG] GraphQLService initialized');
  }

  Future<QueryResult> query(
    String document, {
    Map<String, dynamic> variables = const {},
  }) {
    print('[DEBUG] ▶️ Running GraphQL query:\n$document\nvars: $variables');
    return _client.query(
      QueryOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
  }
}
