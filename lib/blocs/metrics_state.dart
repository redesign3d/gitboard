import 'package:equatable/equatable.dart';

import '../models/metrics.dart';

abstract class MetricsState extends Equatable {
  const MetricsState();

  @override
  List<Object?> get props => [];
}

class MetricsInitial extends MetricsState {}

class MetricsLoadInProgress extends MetricsState {
  final Metrics? previous;
  final DateTime? lastUpdated;

  const MetricsLoadInProgress({this.previous, this.lastUpdated});

  @override
  List<Object?> get props => [previous, lastUpdated];
}

class MetricsLoadSuccess extends MetricsState {
  final Metrics metrics;
  final DateTime lastUpdated;

  const MetricsLoadSuccess({
    required this.metrics,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [metrics, lastUpdated];
}

class MetricsLoadFailure extends MetricsState {
  final String error;
  final Metrics? previous;
  final DateTime? lastUpdated;

  const MetricsLoadFailure({
    required this.error,
    this.previous,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [error, previous, lastUpdated];
}
