import 'package:flutter/material.dart';

class Heatmap extends StatelessWidget {
  final List<int> data;

  const Heatmap({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: data.map((count) {
          final ratio = maxValue > 0 ? count / maxValue : 0.0;
          final color = Color.lerp(
            Colors.grey.shade300,
            Theme.of(context).primaryColor,
            ratio,
          )!;
          return Container(
            width: 12,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
