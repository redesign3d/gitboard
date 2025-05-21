import 'package:equatable/equatable.dart';

class GitHubEvent extends Equatable {
  final String type;         // e.g. “PushEvent”, “ForkEvent”
  final String actor;        // username
  final DateTime createdAt;  // event timestamp
  final String repoName;     // owner/repo
  // you can extend this with payload details (e.g. branch, commit count)

  const GitHubEvent({
    required this.type,
    required this.actor,
    required this.createdAt,
    required this.repoName,
  });

  @override
  List<Object?> get props => [type, actor, createdAt, repoName];

  factory GitHubEvent.fromJson(Map<String, dynamic> json) {
    return GitHubEvent(
      type: json['type'] as String,
      actor: json['actor']['login'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      repoName: json['repo']['name'] as String,
    );
  }
}
