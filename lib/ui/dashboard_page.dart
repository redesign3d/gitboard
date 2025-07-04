import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../blocs/metrics_bloc.dart';
import '../blocs/metrics_state.dart';
import '../blocs/activity_bloc.dart';
import '../blocs/activity_state.dart';
import '../blocs/data_stream_bloc.dart';
import '../repository/events_repository.dart';
import '../models/metrics.dart';
import 'widgets/header.dart';
import 'widgets/sub_header.dart';
import 'widgets/lines_metric.dart';
import 'widgets/activity_graph.dart';
import 'widgets/language_breakdown.dart';
import 'widgets/offline_banner.dart';
import 'widgets/data_stream_sidebar.dart';
import 'widgets/main_view_widget.dart';

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
      final hasData = state is MetricsLoadSuccess ||
          (state is MetricsLoadFailure && state.previous != null);
      if (hasData) {
        final updated = state is MetricsLoadSuccess
            ? state.lastUpdated
            : (state as MetricsLoadFailure).lastUpdated!;
        setState(() => _lastUpdated = updated);
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
      setState(() =>
          _timeUntilNext = diff.isNegative ? Duration.zero : diff);
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
    final cardColor = Theme.of(context).cardColor;
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Header
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

            // Data stream panel only between sub-header and bottom row
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: MainViewWidget(),
                ),
                  const SizedBox(width: 10),

                  // Sidebar
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
            const SizedBox(height: 10),

            // Bottom row: Code Lines / Activity / Language
            SizedBox(
              height: 183,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2, // Commit summary widget
                    child: LinesMetric(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4, // Activity graph
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: cardColor,
                      child: BlocBuilder<ActivityBloc, ActivityState>(
                        builder: (context, activityState) {
                          if (activityState
                              is ActivityLoadInProgress) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (activityState
                              is ActivityLoadFailure) {
                            return Center(
                                child: Text(
                                    'Error: ${activityState.error}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium));
                          }
                          final weeks = (activityState
                                  as ActivityLoadSuccess)
                              .weeks;
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Activity (1y)', style: titleStyle),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: ActivityGraph(weeks: weeks),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3, // Language breakdown
                    child: LanguageBreakdown(
                      languages:
                          context.read<MetricsBloc>().state
                                  is MetricsLoadSuccess
                              ? (context.read<MetricsBloc>().state
                                      as MetricsLoadSuccess)
                                  .metrics
                                  .languages
                              : null,
                      isLoading: context
                              .read<MetricsBloc>()
                              .state
                              is MetricsLoadInProgress,
                      hasError: context
                              .read<MetricsBloc>()
                              .state
                              is MetricsLoadFailure &&
                          (context.read<MetricsBloc>().state
                                  as MetricsLoadFailure)
                              .previous ==
                              null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Offline banner
            BlocBuilder<MetricsBloc, MetricsState>(
              builder: (context, state) {
                if (state is MetricsLoadFailure &&
                    state.previous != null) {
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
