// lib/models/metrics.dart
import 'language_stat.dart';
import 'latest_commit.dart';

class Metrics {
  final int linesAdded;
  final int linesDeleted;
  final List<LanguageStat> languages;

  final int prOpened;
  final int prMerged;
  final int branchCount;
  final int starCount;
  final LatestCommit latestCommit;

  Metrics({
    required this.linesAdded,
    required this.linesDeleted,
    required this.languages,
    required this.prOpened,
    required this.prMerged,
    required this.branchCount,
    required this.starCount,
    required this.latestCommit,
  });
}
