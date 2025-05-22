import 'package:equatable/equatable.dart';

class GitHubEvent extends Equatable {
  final String id;
  final String type;        // "PR opened", "Issue closed", etc.
  final String actor;       // e.g. "alice"
  final DateTime createdAt; // event timestamp
  final String repoName;    // owner/repo

  const GitHubEvent({
    required this.id,
    required this.type,
    required this.actor,
    required this.createdAt,
    required this.repoName,
  });

  @override
  List<Object?> get props => [id, type, actor, createdAt, repoName];

  /// Map a raw `/repos/:owner/:repo/events` JSON to our model
  static GitHubEvent fromRepoJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String;
    final payload = json['payload'] as Map<String, dynamic>?;

    String eventType;
    switch (rawType) {
      case 'PullRequestEvent':
        final action = payload?['action'] as String?;
        final pr = payload?['pull_request'] as Map<String, dynamic>?;
        final merged = pr?['merged'] as bool? ?? false;
        if (action == 'opened') eventType = 'PR opened';
        else if (action == 'closed' && merged) eventType = 'PR merged';
        else if (action == 'closed') eventType = 'PR closed';
        else if (action == 'reopened') eventType = 'PR reopened';
        else eventType = 'PR';
        break;

      case 'CreateEvent':
        if (payload?['ref_type'] == 'branch') {
          eventType = 'Branch created';
        } else {
          throw StateError('Unsupported CreateEvent type');
        }
        break;

      default:
        throw StateError('Unsupported repo event type: $rawType');
    }

    return GitHubEvent(
      id: json['id'] as String,
      type: eventType,
      actor: json['actor']['login'] as String,
      createdAt:
          DateTime.parse(json['created_at'] as String).toLocal(),
      repoName: json['repo']['name'] as String,
    );
  }

  /// Map a raw `/repos/:owner/:repo/issues/events` JSON to our model
  static GitHubEvent fromIssueEventJson(
      Map<String, dynamic> json, String repoName) {
    final rawEvent = json['event'] as String;
    // Note: in issues-events feed, `actor`, `created_at`, and `issue` are top-level
    String eventType;
    switch (rawEvent) {
      case 'opened':
        eventType = json['issue']?['pull_request'] != null
            ? 'PR opened'
            : 'Issue opened';
        break;
      case 'closed':
        eventType = json['issue']?['pull_request'] != null
            ? 'PR closed'
            : 'Issue closed';
        break;
      case 'reopened':
        eventType = json['issue']?['pull_request'] != null
            ? 'PR reopened'
            : 'Issue reopened';
        break;
      default:
        throw StateError('Unsupported issue-event: $rawEvent');
    }

    return GitHubEvent(
      id: json['id'].toString(),
      type: eventType,
      actor: json['actor']['login'] as String,
      createdAt:
          DateTime.parse(json['created_at'] as String).toLocal(),
      repoName: repoName,
    );
  }
}
