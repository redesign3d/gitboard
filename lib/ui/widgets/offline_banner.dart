// lib/ui/widgets/offline_banner.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime lastUpdate;

  const OfflineBanner({
    Key? key,
    required this.lastUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final formatted = DateFormat('yyyy-MM-dd HH:mm').format(lastUpdate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: theme.colorScheme.surface.withOpacity(0.8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Offline — last update: $formatted',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
