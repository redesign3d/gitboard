import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/data_stream_bloc.dart';
import '../../blocs/data_stream_state.dart';

class DataStreamSidebar extends StatelessWidget {
  const DataStreamSidebar({Key? key}) : super(key: key);

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final titleStyle = theme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final widgetColor = const Color(0xFF050A1C);
    final transparentWidgetColor = const Color(0x00050A1C);

    return Container(
      width: 280,
      color: widgetColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Stream', style: titleStyle),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<DataStreamBloc, DataStreamState>(
                  builder: (context, state) {
                    if (state is StreamLoadInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is StreamLoadFailure) {
                      return Center(child: Text('Error: ${state.error}', style: theme.bodyMedium));
                    }
                    final events = (state as StreamLoadSuccess).events;
                    return ListView.builder(
                      reverse: true,
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              style: theme.bodySmall,
                              children: [
                                TextSpan(
                                  text: _fmtTime(e.createdAt) + '  ',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextSpan(text: e.type.replaceAll('Event', '')),
                                TextSpan(text: ' by ${e.actor}'),
                                TextSpan(
                                  text: ' @ ${e.repoName}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [widgetColor, transparentWidgetColor],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
