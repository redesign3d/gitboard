import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/commit_week.dart';

class ActivityGraph extends StatelessWidget {
  final List<CommitWeek> weeks;
  const ActivityGraph({Key? key, required this.weeks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // GitHub-like color scale:
    const colors = [
      Color(0xFFEBEDF0), // 0
      Color(0xFFC6E48B), // 1–low
      Color(0xFF7BC96F), // medium
      Color(0xFF239A3B), // high
      Color(0xFF196127), // very high
    ];

    // Determine max commits in any single day
    final allCounts = weeks.expand((w) => w.days).toList();
    final maxCount = allCounts.isEmpty
        ? 0
        : allCounts.reduce((a, b) => max(a, b));
    final step = maxCount > 0 ? maxCount / (colors.length - 1) : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cols = weeks.length;
        // Each circle + spacing occupies diameter + spacing,
        // totalWidth = cols*diameter + (cols-1)*spacing,
        // and spacing == diameter, so totalWidth = diameter*(2*cols-1)
        final diameter = totalWidth / (2 * cols - 1);
        final spacing = diameter;

        // Center the graph vertically (and horizontally, though width matches)
        return Center(
          child: Row(
            children: List.generate(cols, (i) {
              final week = weeks[i];
              return Padding(
                padding: EdgeInsets.only(right: i == cols - 1 ? 0 : spacing),
                child: Column(
                  children: List.generate(7, (j) {
                    final count = week.days[j];
                    final idx = count == 0
                        ? 0
                        : (count / step).ceil().clamp(0, colors.length - 1);
                    return Padding(
                      padding: EdgeInsets.only(bottom: j == 6 ? 0 : spacing),
                      child: Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[idx],
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
