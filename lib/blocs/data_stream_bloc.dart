import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/events_repository.dart';
import 'data_stream_event.dart';
import 'data_stream_state.dart';

class DataStreamBloc extends Bloc<DataStreamEvent, DataStreamState> {
  final EventsRepository repository;
  final Duration pollInterval;
  Timer? _timer;

  DataStreamBloc({
    required this.repository,
    this.pollInterval = const Duration(seconds: 10),
  }) : super(StreamLoadInProgress()) {
    on<StreamStarted>((_, emit) {
      // kick off polling
      add(StreamTick());
      _timer = Timer.periodic(pollInterval, (_) => add(StreamTick()));
    });
    on<StreamTick>(_onTick);

    // start immediately
    add(StreamStarted());
  }

  Future<void> _onTick(
      StreamTick event, Emitter<DataStreamState> emit) async {
    try {
      final events = await repository.fetchEvents();
      emit(StreamLoadSuccess(events));
    } catch (e) {
      emit(StreamLoadFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
