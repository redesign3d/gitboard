// lib/ui/dashboard_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../blocs/metrics_bloc.dart';
import '../blocs/metrics_state.dart';
import '../models/metrics.dart';
import '../repository/events_repository.dart';
import '../blocs/data_stream_bloc.dart';
import 'widgets/header.dart';
import 'widgets/sub_header.dart';
import 'widgets/lines_metric.dart';
import 'widgets/language_breakdown.dart';
import 'widgets/offline_banner.dart';
import 'widgets/data_stream_sidebar.dart';

class DashboardPage extends StatefulWidget {
  final String owner;
  final String repo;
  final Color addedLineColor;
  final Color deletedLineColor;
  final Duration pollingInterval;

  const DashboardPage({
    Key? key,
    required this.owner,
    required this.repo,
    required this.addedLineColor,
    required this.deletedLineColor,
    required this.pollingInterval,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _lastUpdated;
  Duration _timeUntilNext = Duration.zero;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    context.read<MetricsBloc>().stream.listen((state) {
      final hasData = (state is MetricsLoadSuccess) ||
          (state is MetricsLoadFailure && state.previous != null);
      if (hasData) {
        final updated = state is MetricsLoadSuccess
            ? state.lastUpdated
            : (state as MetricsLoadFailure).lastUpdated!;
        setState(() {
          _lastUpdated = updated;
        });
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = _lastUpdated == null
          ? widget.pollingInterval
          : widget.pollingInterval -
              DateTime.now().difference(_lastUpdated!);
      setState(() {
        _timeUntilNext = diff.isNegative ? Duration.zero : diff;
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = dotenv.env['GITHUB_TOKEN']!;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Top header
            Header(
              owner: widget.owner,
              repo: widget.repo,
              lastUpdated: _lastUpdated,
              nextUpdateIn: _timeUntilNext,
            ),
            const SizedBox(height: 10),

            // Sub-header
            BlocBuilder<MetricsBloc, MetricsState>(
              builder: (context, state) {
                Metrics? m;
                if (state is MetricsLoadSuccess) {
                  m = state.metrics;
                } else if (state is MetricsLoadInProgress ||
                    state is MetricsLoadFailure) {
                  m = (state as dynamic).previous as Metrics?;
                }
                if (m == null) return const SizedBox.shrink();
                return SubHeader(
                  prOpened: m.prOpened,
                  prMerged: m.prMerged,
                  latestCommit: m.latestCommit,
                  branchCount: m.branchCount,
                  starCount: m.starCount,
                );
              },
            ),
            const SizedBox(height: 10),

            // Main content row: grid + sidebar
            Expanded(
              child: Row(
                children: [
                  // Metrics grid
                  Expanded(
                    child: BlocBuilder<MetricsBloc, MetricsState>(
                      builder: (context, state) {
                        final metrics = state is MetricsLoadSuccess
                            ? state.metrics
                            : state is MetricsLoadFailure
                                ? state.previous
                                : state is MetricsLoadInProgress
                                    ? state.previous
                                    : null;
                        final isLoading = state is MetricsLoadInProgress;
                        final hasError = state is MetricsLoadFailure &&
                            state.previous == null;

                        return GridView.count(
                          crossAxisCount:
                              (MediaQuery.of(context).size.width / 400)
                                  .floor()
                                  .clamp(1, 4),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            LinesMetric(
                              linesAdded: metrics?.linesAdded,
                              linesDeleted: metrics?.linesDeleted,
                              isLoading: isLoading,
                              hasError: hasError,
                              addedColor: widget.addedLineColor,
                              deletedColor: widget.deletedLineColor,
                            ),
                            LanguageBreakdown(
                              languages: metrics?.languages,
                              isLoading: isLoading,
                              hasError: hasError,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Sidebar starts under sub-header automatically
                  BlocProvider(
                    create: (_) => DataStreamBloc(
                      repository: EventsRepository(
                        token: token,
                        owner: widget.owner,
                        repo: widget.repo,
                      ),
                      pollInterval: const Duration(seconds: 10),
                    ),
                    child: const DataStreamSidebar(),
                  ),
                ],
              ),
            ),

            // Offline banner
            BlocBuilder<MetricsBloc, MetricsState>(
              builder: (context, state) {
                if (state is MetricsLoadFailure && state.previous != null) {
                  return const OfflineBanner();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
