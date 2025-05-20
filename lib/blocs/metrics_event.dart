// lib/blocs/metrics_event.dart

/// Events for MetricsBloc

abstract class MetricsEvent {}

/// Trigger a fresh metrics fetch
class FetchMetrics extends MetricsEvent {
  final String owner;
  final String repo;
  final DateTime since;

  FetchMetrics({
    required this.owner,
    required this.repo,
    required this.since,
  });
}
