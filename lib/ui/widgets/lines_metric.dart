import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../models/commit_summary.dart';
import '../../repository/commit_summary_repository.dart';

class LinesMetric extends StatefulWidget {
  const LinesMetric({Key? key}) : super(key: key);

  @override
  State<LinesMetric> createState() => _LinesMetricState();
}

class _LinesMetricState extends State<LinesMetric> {
  Future<CommitSummary>? _summaryFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_summaryFuture == null) {
      final token = dotenv.env['GITHUB_TOKEN']!;
      final repoEnv = dotenv.env['GITHUB_REPO']!;
      final parts = repoEnv.split('/');
      final owner = parts[0], repo = parts[1];

      final gqlClient = GraphQLProvider.of(context).value;
      final repository = CommitSummaryRepository(
        gqlClient: gqlClient,
        token: token,
        owner: owner,
        repo: repo,
      );
      _summaryFuture = repository.fetchSummary();
    }
  }

  Color _parseHex(String raw, Color fallback) {
    final cleaned = raw.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final titleStyle =
        theme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = theme.bodyMedium;
    final baseColor = bodyStyle?.color ?? Colors.white;
    final miscColor =
        baseColor.withAlpha((baseColor.a * 0.6 * 255).round());

    final addedColor = _parseHex(
      dotenv.env['LINES_ADDED_COLOR'] ?? '',
      const Color(0xFF01E6B3),
    );
    final deletedColor = _parseHex(
      dotenv.env['LINES_DELETED_COLOR'] ?? '',
      const Color(0xFFFD7A7A),
    );

    return FutureBuilder<CommitSummary>(
      future: _summaryFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _buildLoading(titleStyle);
        }
        if (snap.hasError || snap.data == null) {
          return _buildError(titleStyle);
        }
        final s = snap.data!;
        return Container(
          height: 183,
          padding: const EdgeInsets.all(10),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Changes (28d)', style: titleStyle),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: bodyStyle?.copyWith(color: miscColor),
                  children: [
                    const TextSpan(text: 'On master, '),
                    TextSpan(
                      text: '${s.changedFiles} files have changed',
                      style: bodyStyle?.copyWith(
                        color: baseColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' and there have been '),
                    TextSpan(
                      text: '${s.additions} additions',
                      style: bodyStyle?.copyWith(
                        color: addedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: '${s.deletions} deletions',
                      style: bodyStyle?.copyWith(
                        color: deletedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading(TextStyle? titleStyle) {
    return Container(
      height: 183,
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commits (4w)', style: titleStyle),
          const Spacer(),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildError(TextStyle? titleStyle) {
    return Container(
      height: 183,
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commits (4w)', style: titleStyle),
          const Spacer(),
          const Center(child: Text('Failed to load')),
        ],
      ),
    );
  }
}
