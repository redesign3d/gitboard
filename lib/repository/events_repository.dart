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

  Future<List<GitHubEvent>> fetchEvents() async {
    // 1) Fetch repo‐level events (PR + branch)
    final repoUrl = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/events'
      '?per_page=100'
    );
    final repoRes = await http.get(repoUrl, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
    });
    if (repoRes.statusCode != 200) {
      throw Exception('Failed to load repo events: ${repoRes.statusCode}');
    }
    final repoData = json.decode(repoRes.body) as List<dynamic>;

    final repoEvents = <GitHubEvent>[];
    for (final raw in repoData) {
      final type = raw['type'] as String?; 
      if (type == 'PullRequestEvent' || type == 'CreateEvent') {
        try {
          repoEvents.add(GitHubEvent.fromRepoJson(raw));
        } catch (_) {
          // skip unsupported subtypes
        }
      }
    }

    // 2) Fetch issue‐level events (issue & PR open/close/reopen)
    final issueUrl = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/issues/events'
      '?per_page=100'
    );
    final issueRes = await http.get(issueUrl, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
    });
    if (issueRes.statusCode != 200) {
      throw Exception('Failed to load issue events: ${issueRes.statusCode}');
    }
    final issueData = json.decode(issueRes.body) as List<dynamic>;

    final issueEvents = <GitHubEvent>[];
    for (final raw in issueData) {
      final ev = raw['event'] as String?;
      if (ev == 'opened' || ev == 'closed' || ev == 'reopened') {
        try {
          issueEvents.add(
            GitHubEvent.fromIssueEventJson(raw, '$owner/$repo')
          );
        } catch (_) {
          // skip unsupported
        }
      }
    }

    // 3) Merge & sort descending by time
    final all = [...repoEvents, ...issueEvents];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }
}
