// lib/ui/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../../blocs/metrics_bloc.dart';
import '../../blocs/metrics_event.dart';
import '../../blocs/metrics_state.dart';

import '../widgets/stat_card.dart';
import '../widgets/heatmap.dart';
import '../widgets/language_pie_chart.dart';
import '../widgets/offline_banner.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    context.read<MetricsBloc>().stream.listen((state) {
      if (state is MetricsLoaded) {
        setState(() {
          _lastUpdated = DateTime.now();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repo Dashboard'),
        centerTitle: true,
      ),
      body: BlocBuilder<MetricsBloc, MetricsState>(
        builder: (context, state) {
          if (state is MetricsInitial || state is MetricsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MetricsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading metrics:\n${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final owner = dotenv.env['GITHUB_OWNER']!;
                      final repo = dotenv.env['GITHUB_REPO']!;
                      final since = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      );
                      context.read<MetricsBloc>().add(
                            FetchMetrics(owner: owner, repo: repo, since: since),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // State is MetricsLoaded
          final loaded = state as MetricsLoaded;
          final m = loaded.metrics;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loaded.isStale && _lastUpdated != null)
                  OfflineBanner(lastUpdate: _lastUpdated!),

                Text(
                  'Last updated: ${_lastUpdated != null ? DateFormat('yyyy-MM-dd HH:mm').format(_lastUpdated!) : '-'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    StatCard(label: 'Commits', value: m.commitCount.toString()),
                    StatCard(label: 'Additions', value: m.additions.toString()),
                    StatCard(label: 'Deletions', value: m.deletions.toString()),
                    StatCard(label: 'Unique Authors', value: m.uniqueAuthors.toString()),
                    StatCard(label: 'Issues Opened', value: m.issuesOpened.toString()),
                    StatCard(label: 'Issues Closed', value: m.issuesClosed.toString()),
                    StatCard(label: 'PRs Opened', value: m.prsOpened.toString()),
                    StatCard(label: 'PRs Merged', value: m.prsMerged.toString()),
                    StatCard(label: 'Stars', value: m.starCount.toString()),
                    StatCard(label: 'Forks', value: m.forkCount.toString()),
                    StatCard(label: 'Watchers', value: m.watcherCount.toString()),
                    StatCard(label: 'Create Events', value: m.createEvents.toString()),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  'Weekly Commit Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Heatmap(data: m.weeklyCommitActivity),

                const SizedBox(height: 32),

                Text(
                  'Language Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                LanguagePieChart(data: m.languageBreakdown),
              ],
            ),
          );
        },
      ),
    );
  }
}