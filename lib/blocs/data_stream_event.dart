import 'package:equatable/equatable.dart';
abstract class DataStreamEvent extends Equatable {
  @override List<Object?> get props => [];
}
class StreamStarted extends DataStreamEvent {}
class StreamTick extends DataStreamEvent {}
