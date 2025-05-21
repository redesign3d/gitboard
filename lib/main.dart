// lib/main.dart

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

  // Always reload .env on startup
  await dotenv.load(fileName: '.env');

  final owner = dotenv.env['GITHUB_OWNER']!;
  final repo  = dotenv.env['GITHUB_REPO']!;

  await Hive.initFlutter();

  final githubGraphQL = GithubGraphQL();
  final githubRest    = GithubRest();

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
    final baseTextTheme = GoogleFonts.ibmPlexSansTextTheme();
    const backgroundColor = Color(0xFF050811);
    const cardColor       = Color(0xFF070A1B);
    const accentColor     = Color(0xFF6880A2);

    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        surface: backgroundColor,      // was background
        onSurface: accentColor,        // was onBackground
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: accentColor,
        displayColor: accentColor,
      ),
      iconTheme: const IconThemeData(color: accentColor),
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
                since: DateTime.now().subtract(const Duration(hours: 24)),
              )),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Repo Dashboard',
        theme: theme,
        home: DashboardPage(owner: owner, repo: repo),
      ),
    );
  }
}
