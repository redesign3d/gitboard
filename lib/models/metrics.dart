// lib/models/metrics.dart

import 'package:gitboard/models/language_stat.dart';

class Metrics {
  final int linesAdded;
  final int linesDeleted;
  final List<LanguageStat> languages;

  Metrics({
    required this.linesAdded,
    required this.linesDeleted,
    required this.languages,
  });
}
