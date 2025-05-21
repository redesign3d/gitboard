import 'package:equatable/equatable.dart';

abstract class MetricsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MetricsRequested extends MetricsEvent {}
