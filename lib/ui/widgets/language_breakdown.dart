// lib/ui/widgets/language_breakdown.dart

import 'package:flutter/material.dart';
import '../../models/language_stat.dart';

class LanguageBreakdown extends StatelessWidget {
  final List<LanguageStat>? languages;
  final bool isLoading;
  final bool hasError;

  const LanguageBreakdown({
    Key? key,
    this.languages,
    required this.isLoading,
    required this.hasError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textMedium = theme.textTheme.bodyMedium!;
    final textSmall = theme.textTheme.bodySmall!;
    // Compute 60% opacity on the original color
    final alphaMedium = (textMedium.color!.alpha * 0.6).round();
    final alphaSmall = (textSmall.color!.alpha * 0.6).round();
    final fadedMedium = textMedium.copyWith(
      color: textMedium.color!.withAlpha(alphaMedium),
    );
    final fadedSmall = textSmall.copyWith(
      color: textSmall.color!.withAlpha(alphaSmall),
    );

    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final cardColor = theme.cardColor;

    return Container(
      height: 183,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Language Breakdown (total)', style: titleStyle),
          const SizedBox(height: 8),
          // Center the bar & legend vertically
          Expanded(child: _buildContent(context, fadedMedium, fadedSmall)),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, TextStyle fadedMedium, TextStyle fadedSmall) {
    if (isLoading && languages == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (hasError && (languages == null || languages!.isEmpty)) {
      return Center(child: Text('Failed to load', style: fadedMedium));
    }
    if (languages == null || languages!.isEmpty) {
      return Center(child: Text('No data', style: fadedMedium));
    }

    const barHeight = 8.0;
    final percents = languages!.map((l) => l.percentage).toList();
    final totalCount = percents.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked bar
        LayoutBuilder(builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final widths = <double>[];
          double acc = 0;
          for (var i = 0; i < totalCount; i++) {
            if (i < totalCount - 1) {
              final w = totalWidth * percents[i];
              widths.add(w);
              acc += w;
            } else {
              widths.add(totalWidth - acc);
            }
          }
          return ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(barHeight / 2),
            child: Row(
              children: [
                for (var i = 0; i < totalCount; i++)
                  Container(
                    width: widths[i],
                    height: barHeight,
                    color: Color(
                      int.parse(
                        'FF${languages![i].colorHex.replaceFirst('#', '')}',
                        radix: 16,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        // Legend with 60%-alpha percentages
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: languages!.map((lang) {
            final color = Color(
              int.parse(
                'FF${lang.colorHex.replaceFirst('#', '')}',
                radix: 16,
              ),
            );
            final percentText = '${(lang.percentage * 100).toStringAsFixed(1)}%';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(lang.name, style: fadedMedium),
                const SizedBox(width: 4),
                Text(percentText, style: fadedSmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
