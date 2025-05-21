// lib/ui/pages/dashboard_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../../blocs/metrics_bloc.dart';
import '../../blocs/metrics_event.dart';
import '../../blocs/metrics_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/offline_banner.dart';

class DashboardPage extends StatefulWidget {
  final String owner;
  final String repo;

  const DashboardPage({
    Key? key,
    required this.owner,
    required this.repo,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _lastUpdated;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<MetricsBloc>().stream.listen((state) {
      if (state is MetricsLoaded) _lastUpdated = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _lastUpdated != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _ageText {
    if (_lastUpdated == null) return '';
    final secs = DateTime.now().difference(_lastUpdated!).inSeconds;
    return '${secs}s ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: BlocBuilder<MetricsBloc, MetricsState>(
          builder: (context, state) {
            if (state is MetricsLoading || state is MetricsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MetricsError) {
              return _buildError(state.message);
            }
            final metrics = (state as MetricsLoaded).metrics;

            return Column(
              children: [
                // Repo & age
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${widget.owner}/${widget.repo}',
                        style: theme.textTheme.titleMedium),
                    Text(_lastUpdated != null ? 'Data age: $_ageText' : '',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                if (state.isStale && _lastUpdated != null)
                  OfflineBanner(lastUpdate: _lastUpdated!),
                const SizedBox(height: 10),

                // TOP ROW
                Expanded(
                  flex: 867,
                  child: Row(
                    children: [
                      Expanded(flex: 300, child: _buildPlaceholder(theme)),
                      const SizedBox(width: 10),
                      Expanded(flex: 1280, child: _buildPlaceholder(theme)),
                      const SizedBox(width: 10),
                      Expanded(flex: 300, child: _buildStatsSidebar(theme, metrics)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // BOTTOM ROW
                Expanded(
                  flex: 183,
                  child: Row(
                    children: [
                      Expanded(flex: 300, child: _LanguageBar(breakdown: metrics.languageBreakdown)),
                      const SizedBox(width: 10),
                      Expanded(flex: 635, child: _CodeLines(added: metrics.additions, deleted: metrics.deletions)),
                      const SizedBox(width: 10),
                      Expanded(flex: 945, child: _ContributionGraph(weeklyData: metrics.weeklyCommitActivity)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Error loading metrics:\n$msg',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final since = DateTime.now().subtract(const Duration(hours: 24));
              context
                  .read<MetricsBloc>()
                  .add(FetchMetrics(owner: widget.owner, repo: widget.repo, since: since));
            },
            child: const Text('Retry'),
          ),
        ]),
      );

  Widget _buildPlaceholder(ThemeData theme) => Container(
        color: theme.cardColor, // no borderRadius
      );

  Widget _buildStatsSidebar(ThemeData theme, Metrics m) {
    final stats = [
      ['Commits (last 24h)', m.commitCount],
      ['Additions (last 24h)', m.additions],
      ['Deletions (last 24h)', m.deletions],
      ['Authors (last 24h)', m.uniqueAuthors],
      ['Issues Opened (last 24h)', m.issuesOpened],
      ['Issues Closed (last 24h)', m.issuesClosed],
      ['PRs Opened (last 24h)', m.prsOpened],
      ['PRs Merged (last 24h)', m.prsMerged],
      ['Stars', m.starCount],
      ['Forks', m.forkCount],
      ['Watchers', m.watcherCount],
      ['Create Events (last 24h)', m.createEvents],
    ];

    return Container(
      color: theme.cardColor, // no borderRadius
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: stats
              .map((e) => StatCard(label: e[0] as String, value: (e[1] as int).toString()))
              .toList(),
        ),
      ),
    );
  }
}

const _langColors = {
  'Dart':       Color(0xFF00B4AB),
  'JavaScript': Color(0xFFF1E05A),
  'TypeScript': Color(0xFF2B7489),
  'Python':     Color(0xFF3572A5),
  'Java':       Color(0xFFB07219),
  'C++':        Color(0xFFF34B7D),
  'C#':         Color(0xFF178600),
  'Go':         Color(0xFF00ADD8),
  'Shell':      Color(0xFF89E051),
  'HTML':       Color(0xFFE34C26),
  'CSS':        Color(0xFF563D7C),
};

class _LanguageBar extends StatelessWidget {
  final Map<String, double> breakdown;
  const _LanguageBar({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sort descending, take top 7, sum the rest into "Other"
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.length > 8 ? sorted.take(7).toList() : sorted;
    if (sorted.length > 8) {
      final other = sorted.skip(7).fold<double>(0, (sum, e) => sum + e.value);
      top.add(MapEntry('Other', other));
    }
    final entries = top;

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title
          Text('Languages', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // Bar with rounded ends
          SizedBox(
            height: 10,
            child: Row(children: [
              for (var i = 0; i < entries.length; i++)
                Expanded(
                  flex: (entries[i].value * 1000).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _langColors[entries[i].key] ?? theme.colorScheme.primary,
                      borderRadius: BorderRadius.horizontal(
                        left: i == 0 ? const Radius.circular(4) : Radius.zero,
                        right: i == entries.length - 1 ? const Radius.circular(4) : Radius.zero,
                      ),
                    ),
                  ),
                )
            ]),
          ),
          const SizedBox(height: 12),

          // Legend in two columns
          LayoutBuilder(builder: (context, bc) {
            final itemWidth = (bc.maxWidth - 20) / 2;
            return Wrap(
              spacing: 20,
              runSpacing: 8,
              children: entries.map((e) {
                final color = _langColors[e.key] ?? theme.colorScheme.primary;
                final pct = (e.value * 100).toStringAsFixed(1);
                return SizedBox(
                  width: itemWidth,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(e.key, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 4),
                    Text(
                      '$pct%',
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: theme.textTheme.bodySmall!.color!.withOpacity(0.5)),
                    ),
                  ]),
                );
              }).toList(),
            );
          }),
        ]),
      ),
    );
  }
}

class _CodeLines extends StatelessWidget {
  final int added, deleted;
  const _CodeLines({required this.added, required this.deleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Code Lines Added/Deleted (last 24h)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // Even larger metrics
          RichText(
            text: TextSpan(
              style: theme.textTheme.displayLarge,
              children: [
                TextSpan(text: '+$added', style: const TextStyle(color: Color(0xFF03EAB8))),
                const TextSpan(text: ' / '),
                TextSpan(text: '-$deleted', style: const TextStyle(color: Color(0xFFFC4C85))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _ContributionGraph extends StatelessWidget {
  final List<int> weeklyData;
  const _ContributionGraph({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = weeklyData;
    final nonZero = data.where((c) => c > 0).toList();
    final minNonZero = nonZero.isNotEmpty ? nonZero.reduce(min) : 1;
    final maxVal = data.isNotEmpty ? data.reduce(max) : 1;

    // dates for each column
    final now = DateTime.now();
    final startSunday = now.subtract(Duration(days: now.weekday % 7 + 7 * 55));
    final dates = List.generate(56, (i) => startSunday.add(Duration(days: i * 7)));

    // label first occurrence of each month
    final monthLabels = List<String?>.filled(56, null);
    String? lastMonth;
    for (var i = 0; i < dates.length; i++) {
      final m = DateFormat.MMM().format(dates[i]);
      if (m != lastMonth) {
        monthLabels[i] = m;
        lastMonth = m;
      }
    }

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contributions (last year)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // month labels row
          LayoutBuilder(builder: (context, bc) {
            const spacing = 2.0;
            final cellW = (bc.maxWidth - (spacing * 55)) / 56;
            return Row(children: [
              for (var i = 0; i < 56; i++) ...[
                SizedBox(
                  width: cellW,
                  child: monthLabels[i] != null
                      ? Text(monthLabels[i]!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall)
                      : const SizedBox(),
                ),
                if (i < 55) const SizedBox(width: spacing),
              ]
            ]);
          }),

          const SizedBox(height: 12),

          // the 7×56 heatmap via AspectRatio
          AspectRatio(
            aspectRatio: 56 / 7,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 56,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 56 * 7,
              itemBuilder: (_, i) {
                final count = (i < data.length) ? data[i] : 0;
                late Color color;
                if (count == 0) {
                  color = Colors.transparent;
                } else if (maxVal == minNonZero) {
                  color = const Color(0xFF012811);
                } else {
                  final t = (count - minNonZero) / (maxVal - minNonZero);
                  color = Color.lerp(const Color(0xFF012811), Colors.white, t)!;
                }
                return Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
              },
            ),
          ),
        ]),
      ),
    );
  }
}
