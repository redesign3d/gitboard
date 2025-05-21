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
  await dotenv.load(fileName: '.env');
  await initHiveForFlutter();

  final repoEnv = dotenv.env['GITHUB_REPO']!;
  final parts = repoEnv.split('/');
  final owner = parts[0], repo = parts[1];

  final token = dotenv.env['GITHUB_TOKEN']!;
  final polling = int.tryParse(dotenv.env['POLLING_INTERVAL_SECONDS'] ?? '') ?? 30;
  final pollingInterval = Duration(seconds: polling);

  Color parseHex(String raw, Color fallback) {
    final cleaned = raw.replaceFirst('#', '');
    if (cleaned.length != 6 && cleaned.length != 8) return fallback;
    final val = int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(val);
  }

  final addedColor = parseHex(dotenv.env['LINES_ADDED_COLOR'] ?? '', const Color(0xFF01E6B3));
  final deletedColor = parseHex(dotenv.env['LINES_DELETED_COLOR'] ?? '', const Color(0xFFFD7A7A));

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
    addedLineColor: addedColor,
    deletedLineColor: deletedColor,
  ));
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
        home: DashboardPage(
          owner: owner,
          repo: repo,
          addedLineColor: addedLineColor,
          deletedLineColor: deletedLineColor,
          pollingInterval: pollingInterval,
        ),
        builder: (context, child) => Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: child,
        ),
      ),
    );
  }
}
