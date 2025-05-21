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
    final theme = Theme.of(context).textTheme;
    final titleStyle = theme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Container(
      height: 183,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Color(0xFF050A1C)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Language Breakdown (total)', style: titleStyle),
          const SizedBox(height: 8),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    if (isLoading && languages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError && (languages == null || languages!.isEmpty)) {
      return Center(child: Text('Failed to load', style: theme.bodyMedium));
    }
    if (languages == null || languages!.isEmpty) {
      return Center(child: Text('No data', style: theme.bodyMedium));
    }

    // build bar + legend
    const barHeight = 8.0;
    final percents = languages!.map((l) => l.percentage).toList();
    final totalCount = percents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked bar with precise widths & rounded ends
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
        // Legend with 60%‐alpha percentages
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
            final percentText =
                '${(lang.percentage * 100).toStringAsFixed(1)}%';
            final base = theme.bodyMedium!;
            final alpha = (base.color!.a * 0.6 * 255).round();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(lang.name, style: base),
                const SizedBox(width: 4),
                Text(
                  percentText,
                  style: base.copyWith(color: base.color!.withAlpha(alpha)),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
