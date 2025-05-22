// lib/blocs/activity_event.dart

import 'package:equatable/equatable.dart';

abstract class ActivityEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityStarted extends ActivityEvent {}

class ActivityTick extends ActivityEvent {}
