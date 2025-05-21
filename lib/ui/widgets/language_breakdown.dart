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
    return Container(
      height: 183,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF050A1C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Language Breakdown (total)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && languages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError && (languages == null || languages!.isEmpty)) {
      return const Center(child: Text('Failed to load'));
    }
    if (languages == null || languages!.isEmpty) {
      return const Center(child: Text('No data'));
    }

    const barHeight = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) ClipRRect for perfectly rounded ends + antialias
        LayoutBuilder(builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final percents = languages!.map((l) => l.percentage).toList();

          // compute pixel widths, ensuring last fills remainder
          final widths = <double>[];
          double acc = 0;
          for (var i = 0; i < percents.length; i++) {
            if (i < percents.length - 1) {
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
              mainAxisSize: MainAxisSize.max,
              children: [
                for (var i = 0; i < languages!.length; i++)
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
        // 2) Legend with 60% opacity on percentage
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
            final baseStyle = Theme.of(context).textTheme.bodyMedium!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(lang.name, style: baseStyle),
                const SizedBox(width: 4),
                Text(
                  percentText,
                  style: baseStyle.copyWith(color: baseStyle.color?.withOpacity(0.6)),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
