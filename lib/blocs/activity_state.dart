// lib/blocs/activity_state.dart

import 'package:equatable/equatable.dart';
import '../models/commit_week.dart';

abstract class ActivityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityLoadInProgress extends ActivityState {}

class ActivityLoadSuccess extends ActivityState {
  final List<CommitWeek> weeks;
  ActivityLoadSuccess(this.weeks);
  @override
  List<Object?> get props => [weeks];
}

class ActivityLoadFailure extends ActivityState {
  final String error;
  ActivityLoadFailure(this.error);
  @override
  List<Object?> get props => [error];
}
