import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_event.dart';

class EventsRepository {
  final String token;
  final String owner;
  final String repo;

  EventsRepository({
    required this.token,
    required this.owner,
    required this.repo,
  });

  /// Fetches the most recent events for the repo.
  Future<List<GitHubEvent>> fetchEvents() async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/events');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load events: ${res.statusCode}');
    }
    final data = json.decode(res.body) as List<dynamic>;
    return data
        .map((e) => GitHubEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
