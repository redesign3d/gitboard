import 'package:equatable/equatable.dart';

class CommitWeek extends Equatable {
  /// UNIX timestamp (seconds) of the start of this week
  final DateTime weekStart;

  /// Commits per day, Sun→Sat
  final List<int> days;

  const CommitWeek({
    required this.weekStart,
    required this.days,
  });

  @override
  List<Object?> get props => [weekStart, days];
}
