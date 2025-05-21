import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'services/graphql_service.dart';
import 'repository/metrics_repository.dart';
import 'blocs/metrics_bloc.dart';
import 'ui/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    print('[DEBUG] .env loaded: ${dotenv.env}');

    await initHiveForFlutter();
    print('[DEBUG] initHiveForFlutter complete');

    final repoEnv = dotenv.env['GITHUB_REPO'];
    final token = dotenv.env['GITHUB_TOKEN'];
    final pollingEnv = dotenv.env['POLLING_INTERVAL_SECONDS'];
    final addedEnv = dotenv.env['LINES_ADDED_COLOR']?.trim();
    final deletedEnv = dotenv.env['LINES_DELETED_COLOR']?.trim();

    if (repoEnv == null || token == null) {
      throw StateError('GITHUB_REPO or GITHUB_TOKEN not set in .env');
    }
    final parts = repoEnv.split('/');
    if (parts.length != 2) {
      throw StateError(
          'GITHUB_REPO must be in "owner/repo" format, got: $repoEnv');
    }
    final owner = parts[0], repo = parts[1];

    final pollingSeconds =
        int.tryParse(pollingEnv ?? '') ?? 30; 
    final pollingInterval = Duration(seconds: pollingSeconds);

    String safeHex(String? raw, String fallback) {
      if (raw == null || raw.isEmpty) return fallback;
      final cleaned = raw.replaceFirst('#', '');
      if (cleaned.length != 6 && cleaned.length != 8) return fallback;
      return '#$cleaned';
    }

    final addedHex = safeHex(addedEnv, '#01E6B3');
    final deletedHex = safeHex(deletedEnv, '#FD7A7A');

    Color hexToColor(String hex) {
      final cleaned = hex.replaceFirst('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    }

    print('[DEBUG] Config → owner: $owner, repo: $repo, '
        'interval: ${pollingInterval.inSeconds}s, '
        'addedHex: $addedHex, deletedHex: $deletedHex');

    final graphQLService = GraphQLService(token);
    final repository = MetricsRepository(
      service: graphQLService,
      owner: owner,
      name: repo,
    );

    runApp(MyApp(
      owner: owner,
      repo: repo,
      repository: repository,
      pollingInterval: pollingInterval,
      addedLineColor: hexToColor(addedHex),
      deletedLineColor: hexToColor(deletedHex),
    ));
  } catch (e, st) {
    print('[ERROR] Failed to initialize app: $e\n$st');
  }
}

class MyApp extends StatelessWidget {
  final String owner;
  final String repo;
  final MetricsRepository repository;
  final Duration pollingInterval;
  final Color addedLineColor;
  final Color deletedLineColor;

  const MyApp({
    Key? key,
    required this.owner,
    required this.repo,
    required this.repository,
    required this.pollingInterval,
    required this.addedLineColor,
    required this.deletedLineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF677FA2);

    return BlocProvider<MetricsBloc>(
      create: (_) => MetricsBloc(
        repository: repository,
        pollingInterval: pollingInterval,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF000000),
          canvasColor: const Color(0xFF000000),
          cardColor: const Color(0xFF050A1C),
          textTheme: GoogleFonts.ibmPlexSansTextTheme(
            ThemeData.dark().textTheme,
          ).apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),
        ),
        home: Builder(builder: (context) {
          return DashboardPage(
            owner: owner,
            repo: repo,
            addedLineColor: addedLineColor,
            deletedLineColor: deletedLineColor,
            pollingInterval: pollingInterval,
          );
        }),
        builder: (context, child) => Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: child,
        ),
      ),
    );
  }
}
