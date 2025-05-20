// lib/blocs/metrics_state.dart

/// A simple model to hold all fetched metrics.
class Metrics {
  final int commitCount;
  final int additions;
  final int deletions;
  final int uniqueAuthors;
  final int issuesOpened;
  final int issuesClosed;
  final int prsOpened;
  final int prsMerged;
  final int starCount;
  final int forkCount;
  final int watcherCount;
  final Map<String, double> languageBreakdown;
  final List<int> weeklyCommitActivity;
  final int createEvents;

  Metrics({
    required this.commitCount,
    required this.additions,
    required this.deletions,
    required this.uniqueAuthors,
    required this.issuesOpened,
    required this.issuesClosed,
    required this.prsOpened,
    required this.prsMerged,
    required this.starCount,
    required this.forkCount,
    required this.watcherCount,
    required this.languageBreakdown,
    required this.weeklyCommitActivity,
    required this.createEvents,
  });
}

/// States emitted by MetricsBloc
abstract class MetricsState {}

/// Initial state (nothing fetched yet)
class MetricsInitial extends MetricsState {}

/// Loading indicator
class MetricsLoading extends MetricsState {}

/// Successful load
class MetricsLoaded extends MetricsState {
  final Metrics metrics;
  /// If you later wire in offline/stale logic, toggle this flag.
  final bool isStale;

  MetricsLoaded({
    required this.metrics,
    this.isStale = false,
  });
}

/// Error state
class MetricsError extends MetricsState {
  final String message;

  MetricsError({required this.message});
}
