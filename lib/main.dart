// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/github_graphql.dart';
import 'core/services/github_rest.dart';
import 'blocs/metrics_bloc.dart';
import 'blocs/metrics_event.dart';
import 'ui/pages/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the bundled .env asset
  await dotenv.load(fileName: '.env');

  final owner = dotenv.env['GITHUB_OWNER']!;
  final repo  = dotenv.env['GITHUB_REPO']!;

  // Init Hive (for future caching)
  await Hive.initFlutter();

  // Instantiate GitHub API services
  final githubGraphQL = GithubGraphQL();
  final githubRest    = GithubRest();

  // Start the app
  runApp(MyApp(
    githubGraphQL: githubGraphQL,
    githubRest:    githubRest,
    owner:         owner,
    repo:          repo,
  ));
}

class MyApp extends StatelessWidget {
  final GithubGraphQL githubGraphQL;
  final GithubRest    githubRest;
  final String        owner;
  final String        repo;

  const MyApp({
    Key? key,
    required this.githubGraphQL,
    required this.githubRest,
    required this.owner,
    required this.repo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Base IBM Plex Sans text theme
    final baseTextTheme = GoogleFonts.ibmPlexSansTextTheme();

    // Custom color scheme
    const background = Color(0xFF050811);
    const surface    = Color(0xFF070A1B);
    const accent     = Color(0xFF6880A2);

    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      primaryColor: accent,
      colorScheme: ColorScheme.dark(
        primary: accent,
        background: background,
        surface: surface,
        onBackground: accent,
        onSurface: accent,
        onPrimary: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: accent,
        displayColor: accent,
      ),
      iconTheme: const IconThemeData(color: accent),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: accent,
        elevation: 0,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<MetricsBloc>(
          create: (_) => MetricsBloc(
            githubGraphQL: githubGraphQL,
            githubRest:    githubRest,
          )..add(FetchMetrics(
                owner: owner,
                repo:  repo,
                since: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
              )),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Repo Dashboard',
        theme: theme,
        home: const DashboardPage(),
      ),
    );
  }
}
