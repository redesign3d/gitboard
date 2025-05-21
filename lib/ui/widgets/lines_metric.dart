import 'package:flutter/material.dart';

class LinesMetric extends StatelessWidget {
  final int? linesAdded;
  final int? linesDeleted;
  final bool isLoading;
  final bool hasError;
  final Color addedColor;
  final Color deletedColor;

  const LinesMetric({
    Key? key,
    this.linesAdded,
    this.linesDeleted,
    required this.isLoading,
    required this.hasError,
    required this.addedColor,
    required this.deletedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final titleStyle = theme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    Widget content;
    if (isLoading && linesAdded == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (hasError && linesAdded == null) {
      content = const Center(child: Text('Failed to load'));
    } else {
      content = Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: theme.displaySmall,
            children: [
              TextSpan(
                text: '${linesAdded ?? 0}',
                style: TextStyle(
                  color: addedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' / '),
              TextSpan(
                text: '${linesDeleted ?? 0}',
                style: TextStyle(
                  color: deletedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 183,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF050A1C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code Lines Added / Removed (last 24 hrs)', style: titleStyle),
          const SizedBox(height: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}
