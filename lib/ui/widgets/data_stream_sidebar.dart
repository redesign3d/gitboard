// lib/ui/widgets/data_stream_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/data_stream_bloc.dart';
import '../../blocs/data_stream_state.dart';

class DataStreamSidebar extends StatelessWidget {
  const DataStreamSidebar({Key? key}) : super(key: key);

  String _fmtDateTime(DateTime dt) {
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    return '${dt.year.toString().padLeft(4, '0')}-'
           '${dt.month.toString().padLeft(2, '0')}-'
           '${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}:'
           '${dt.second.toString().padLeft(2, '0')} '
           '[GMT$sign$hours]';
  }

  Color _parseHex(String raw, Color fallback) {
    final cleaned = raw.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSmall = theme.textTheme.bodySmall!;
    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final bgColor = theme.cardColor;

    // Configurable colors from .env
    final miscHex = dotenv.env['STREAM_MISC_COLOR'] ?? '#677FA2';
    final typeHex = dotenv.env['STREAM_TYPE_COLOR'] ?? '#6F508F';
    final userHex = dotenv.env['STREAM_USER_COLOR'] ?? '#1E6E63';

    final miscColor = _parseHex(miscHex, textSmall.color!);
    final typeColor = _parseHex(typeHex, const Color(0xFF6F508F));
    final userColor = _parseHex(userHex, const Color(0xFF1E6E63));

    // 60% opacity for misc elements (timestamp, ID, "from")
    final miscAlpha = (miscColor.alpha * 0.6).round();
    final miscAlphaColor = miscColor.withAlpha(miscAlpha);

    final contentStyle =
        GoogleFonts.ibmPlexMono(textStyle: textSmall);

    return Container(
      width: 364,
      color: bgColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Stream', style: titleStyle),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<DataStreamBloc, DataStreamState>(
                  builder: (context, state) {
                    if (state is StreamLoadInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is StreamLoadFailure) {
                      return Center(
                        child: Text(
                          'Error: ${state.error}',
                          style: contentStyle.copyWith(color: miscAlphaColor),
                        ),
                      );
                    }
                    final events = (state as StreamLoadSuccess).events;
                    if (events.isEmpty) {
                      return Center(
                        child: Text(
                          'No activity',
                          style: contentStyle.copyWith(color: miscAlphaColor),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.zero,
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timestamp
                              Text(
                                _fmtDateTime(e.createdAt),
                                style: contentStyle.copyWith(color: miscAlphaColor),
                              ),
                              const SizedBox(height: 4),
                              // ID and Event Type
                              RichText(
                                text: TextSpan(
                                  style: contentStyle,
                                  children: [
                                    TextSpan(
                                      text: '[${e.id}] : ',
                                      style: TextStyle(color: miscAlphaColor),
                                    ),
                                    TextSpan(
                                      text: e.type,
                                      style: TextStyle(color: typeColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // from user
                              RichText(
                                text: TextSpan(
                                  style: contentStyle,
                                  children: [
                                    TextSpan(
                                      text: 'from ',
                                      style: TextStyle(color: miscAlphaColor),
                                    ),
                                    TextSpan(
                                      text: e.actor,
                                      style: TextStyle(color: userColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                // Gradient fade-in under title (200px tall)
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
                        colors: [
                          bgColor,
                          bgColor.withAlpha(0),
                        ],
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
