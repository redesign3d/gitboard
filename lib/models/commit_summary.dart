class CommitSummary {
  /// Number of unique authors who pushed commits (excluding merges)
  final int authorsCount;

  /// Total commits pushed (excluding merges)
  final int commitsCount;

  /// Total files changed on the default branch (master/main)
  final int changedFiles;

  /// Total lines added on the default branch
  final int additions;

  /// Total lines deleted on the default branch
  final int deletions;

  const CommitSummary({
    required this.authorsCount,
    required this.commitsCount,
    required this.changedFiles,
    required this.additions,
    required this.deletions,
  });
}
