// lib/models/language_stat.dart

import 'package:equatable/equatable.dart';

class LanguageStat extends Equatable {
  final String name;
  final String colorHex;
  final double percentage;

  const LanguageStat({
    required this.name,
    required this.colorHex,
    required this.percentage,
  });

  @override
  List<Object?> get props => [name, colorHex, percentage];
}
