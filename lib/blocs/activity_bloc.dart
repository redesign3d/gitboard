// lib/blocs/activity_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/activity_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository repository;
  final Duration pollInterval;
  Timer? _timer;

  ActivityBloc({
    required this.repository,
    this.pollInterval = const Duration(seconds: 30),
  }) : super(ActivityLoadInProgress()) {
    on<ActivityStarted>((_, emit) {
      add(ActivityTick());
      _timer = Timer.periodic(pollInterval, (_) => add(ActivityTick()));
    });
    on<ActivityTick>(_onTick);
    // kick off
    add(ActivityStarted());
  }

  Future<void> _onTick(
      ActivityTick event, Emitter<ActivityState> emit) async {
    try {
      final weeks = await repository.fetchActivity();
      emit(ActivityLoadSuccess(weeks));
    } catch (e) {
      emit(ActivityLoadFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
