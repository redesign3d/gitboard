import 'package:equatable/equatable.dart';

class LatestCommit extends Equatable {
  final String author;
  final String message;
  final String id;
  final int minutesAgo;

  const LatestCommit({
    required this.author,
    required this.message,
    required this.id,
    required this.minutesAgo,
  });

  @override
  List<Object?> get props => [author, message, id, minutesAgo];
}
