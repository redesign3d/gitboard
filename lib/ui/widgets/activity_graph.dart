// lib/ui/widgets/activity_graph.dart

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

    // Flatten to find max per-day count
    final allCounts = weeks.expand((w) => w.days).toList();
    final maxCount = allCounts.isEmpty ? 0 : allCounts.reduce((a, b) => a > b ? a : b);
    // If maxCount==0, everything will be color[0]
    double step = maxCount > 0 ? maxCount / (colors.length - 1) : 1;

    return SizedBox(
      height: 183, // same as other widgets
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final spacing = 2.0;
          final cols = weeks.length;
          final totalSpacing = spacing * (cols - 1);
          final cellSize = (constraints.maxWidth - totalSpacing) / cols;

          return Row(
            children: [
              for (var week in weeks)
                Column(
                  children: [
                    for (var count in week.days)
                      Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(bottom: spacing),
                        color: colors[
                            (count == 0 ? 0 : (count / step).ceil())
                                .clamp(0, colors.length - 1)],
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
