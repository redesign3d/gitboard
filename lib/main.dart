// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/github_graphql.dart';
import 'core/services/github_rest.dart';
import 'blocs/metrics_bloc.dart';
import 'blocs/metrics_event.dart';
import 'ui/pages/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env (declare in pubspec.yaml under assets)
  await dotenv.load(fileName: '.env');

  final owner = dotenv.env['GITHUB_OWNER']!;
  final repo  = dotenv.env['GITHUB_REPO']!;

  // Initialize Hive for caching metrics
  await Hive.initFlutter();

  // Instantiate GitHub service clients
  final githubGraphQL = GithubGraphQL();
  final githubRest    = GithubRest();

  // Start the app with MetricsBloc
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
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
        title: 'Repo Dashboard',
        theme: ThemeData.light(),
        home: const DashboardPage(),
      ),
    );
  }
}
