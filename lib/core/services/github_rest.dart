// lib/core/services/github_rest.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GithubRest {
  final Dio _dio;

  GithubRest()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.github.com',
          headers: {
            'Authorization': 'Bearer ${dotenv.env['GITHUB_TOKEN']}',
            'Accept': 'application/vnd.github.v3+json',
          },
        ));

  /// Returns the total commits per week for the last ~52 weeks.
  Future<List<int>> fetchWeeklyCommitActivity({
    required String owner,
    required String repo,
  }) async {
    final response = await _dio.get('/repos/$owner/$repo/stats/commit_activity');
    final data = response.data;
    if (data is List) {
      // Each element: { week: <int>, total: <int>, days: [<int>,…] }
      return data.map<int>((e) {
        if (e is Map<String, dynamic> && e.containsKey('total')) {
          return (e['total'] as int);
        } else {
          return 0;
        }
      }).toList();
    } else {
      // Unexpected shape
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Expected list but got ${data.runtimeType}',
      );
    }
  }

  /// Counts CreateEvent instances (branches/tags) since [since], paging as needed.
  Future<int> fetchCreateEvents({
    required String owner,
    required String repo,
    required DateTime since,
  }) async {
    var page = 1;
    var totalCount = 0;

    while (true) {
      final response = await _dio.get('/repos/$owner/$repo/events',
        queryParameters: {'per_page': 100, 'page': page},
      );
      final events = response.data;
      if (events is List) {
        if (events.isEmpty) break;
        totalCount += events.where((e) {
          if (e is Map<String, dynamic>) {
            final type = e['type'];
            final createdAt = DateTime.tryParse(e['created_at'] ?? '');
            return type == 'CreateEvent' && createdAt != null && createdAt.isAfter(since);
          }
          return false;
        }).length;
        if (events.length < 100) break;
        page++;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Expected events list but got ${events.runtimeType}',
        );
      }
    }

    return totalCount;
  }
}
