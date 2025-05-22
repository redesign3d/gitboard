// lib/repository/activity_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commit_week.dart';

class ActivityRepository {
  final String token;
  final String owner;
  final String repo;

  ActivityRepository({
    required this.token,
    required this.owner,
    required this.repo,
  });

  Future<List<CommitWeek>> fetchActivity() async {
    final url = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/stats/commit_activity'
    );
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load activity: ${res.statusCode}');
    }
    final data = json.decode(res.body) as List<dynamic>;
    // Map each week
    return data.map((raw) {
      final weekSeconds = raw['week'] as int;
      final days = List<int>.from(raw['days'] as List<dynamic>);
      return CommitWeek(
        weekStart: DateTime.fromMillisecondsSinceEpoch(weekSeconds * 1000)
            .toLocal(),
        days: days,
      );
    }).toList();
  }
}
