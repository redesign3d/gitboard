import 'package:equatable/equatable.dart';
import '../models/github_event.dart';

abstract class DataStreamState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StreamLoadInProgress extends DataStreamState {}

class StreamLoadSuccess extends DataStreamState {
  final List<GitHubEvent> events;

  StreamLoadSuccess(this.events);

  @override
  List<Object?> get props => [events];
}

class StreamLoadFailure extends DataStreamState {
  final String error;

  StreamLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}
