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
    final formatted = DateFormat('yyyy-MM-dd HH:mm').format(lastUpdate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.6),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Offline — last update: $formatted',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
