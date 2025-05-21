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
    Widget content;
    if (isLoading && linesAdded == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (hasError && linesAdded == null) {
      content = const Center(child: Text('Failed to load'));
    } else {
      // Single "added / deleted" line, left-aligned, with colored spans
      content = Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium,
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
      height: 183, // fixed height
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF050A1C), // widget fill
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code Lines Added / Removed (last 24 hrs)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // content takes remaining space
          Expanded(child: content),
        ],
      ),
    );
  }
}
