// lib/ui/widgets/sub_header.dart
import 'package:flutter/material.dart';
import '../../models/latest_commit.dart';

class SubHeader extends StatelessWidget {
  final int prOpened;
  final int prMerged;
  final LatestCommit latestCommit;
  final int branchCount;  // renamed
  final int starCount;

  const SubHeader({
    Key? key,
    required this.prOpened,
    required this.prMerged,
    required this.latestCommit,
    required this.branchCount,
    required this.starCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    // apply 60% opacity to the update counters:
    final counterStyle = textStyle.copyWith(
      color: textStyle.color?.withOpacity(0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      color: const Color(0xFF050A1C),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PRs opened/merged (24h): $prOpened / $prMerged',
              style: counterStyle,
            ),
          ),
          Expanded(
            child: Text(
              'Latest: ${latestCommit.author}: ${latestCommit.message} (${latestCommit.id}) — ${latestCommit.minutesAgo}m ago',
              style: counterStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Icon(Icons.call_split, size: 16, color: textStyle.color),
              const SizedBox(width: 4),
              Text('$branchCount', style: counterStyle),
            ],
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              Icon(Icons.star, size: 16, color: textStyle.color),
              const SizedBox(width: 4),
              Text('$starCount', style: counterStyle),
            ],
          ),
        ],
      ),
    );
  }
}
