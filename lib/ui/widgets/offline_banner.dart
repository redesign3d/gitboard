import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF050A1C),
      child: const Center(
        child: Text(
          'Dashboard is currently offline. Showing stale data where available.',
          style: TextStyle(
            color: Color(0xFF677FA2),
          ),
        ),
      ),
    );
  }
}
