// lib/blocs/metrics_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/metrics.dart';               // ← add this
import '../repository/metrics_repository.dart';
import 'metrics_event.dart';
import 'metrics_state.dart';

class MetricsBloc extends Bloc<MetricsEvent, MetricsState> {
  final MetricsRepository repository;
  final Duration pollingInterval;
  Timer? _timer;

  MetricsBloc({
    required this.repository,
    required this.pollingInterval,
  }) : super(MetricsInitial()) {
    on<MetricsRequested>(_onRequested);

    // fire once immediately
    add(MetricsRequested());
    // then poll
    _timer = Timer.periodic(pollingInterval, (_) {
      add(MetricsRequested());
    });
  }

  Future<void> _onRequested(
      MetricsRequested event, Emitter<MetricsState> emit) async {
    // capture previous
    Metrics? prevMetrics;
    DateTime? prevTime;
    if (state is MetricsLoadSuccess) {
      prevMetrics = (state as MetricsLoadSuccess).metrics;
      prevTime = (state as MetricsLoadSuccess).lastUpdated;
    } else if (state is MetricsLoadInProgress) {
      prevMetrics = (state as MetricsLoadInProgress).previous;
      prevTime = (state as MetricsLoadInProgress).lastUpdated;
    } else if (state is MetricsLoadFailure) {
      prevMetrics = (state as MetricsLoadFailure).previous;
      prevTime = (state as MetricsLoadFailure).lastUpdated;
    }

    emit(MetricsLoadInProgress(previous: prevMetrics, lastUpdated: prevTime));

    try {
      final metrics = await repository.fetchMetrics();
      final now = DateTime.now();
      emit(MetricsLoadSuccess(metrics: metrics, lastUpdated: now));
    } catch (e) {
      emit(MetricsLoadFailure(
        error: e.toString(),
        previous: prevMetrics,
        lastUpdated: prevTime,
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
