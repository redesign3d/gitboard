import 'package:flutter/material.dart';

class MainViewWidget extends StatelessWidget {
  const MainViewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    return Container(
      decoration: BoxDecoration(color: cardColor),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Main', style: titleStyle),
          // empty content for now
        ],
      ),
    );
  }
}
