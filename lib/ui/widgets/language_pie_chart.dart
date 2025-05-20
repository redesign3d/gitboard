import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LanguagePieChart extends StatelessWidget {
  final Map<String, double> data;

  const LanguagePieChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  static const List<Color> _palette = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final entries = data.entries.where((e) => e.value > 0).toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percent = entry.value * 100;
      sections.add(PieChartSectionData(
        color: _palette[i % _palette.length],
        value: percent,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    if (sections.isEmpty) {
      return const Center(child: Text('No language data'));
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 0,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
