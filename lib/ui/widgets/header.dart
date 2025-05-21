import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String owner;
  final String repo;
  final DateTime? lastUpdated;
  final Duration nextUpdateIn;

  const Header({
    Key? key,
    required this.owner,
    required this.repo,
    this.lastUpdated,
    required this.nextUpdateIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lastText = lastUpdated == null
        ? 'Loading…'
        : 'Last update: ${_fmtDateTime(lastUpdated!)}';
    final nextText = lastUpdated == null
        ? ''
        : 'Next in: ${_fmtDuration(nextUpdateIn)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$owner/$repo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(lastText),
            if (nextText.isNotEmpty) Text(nextText),
          ],
        ),
      ],
    );
  }

  String _fmtDateTime(DateTime dt) {
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final da = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$mo-$da $h:$mi:$s';
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
