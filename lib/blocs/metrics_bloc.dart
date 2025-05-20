import 'package:bloc/bloc.dart';
import '../core/services/github_graphql.dart';
import '../core/services/github_rest.dart';
import 'metrics_event.dart';
import 'metrics_state.dart';

class MetricsBloc extends Bloc<MetricsEvent, MetricsState> {
  final GithubGraphQL githubGraphQL;
  final GithubRest githubRest;

  MetricsBloc({
    required this.githubGraphQL,
    required this.githubRest,
  }) : super(MetricsInitial()) {
    on<FetchMetrics>(_onFetchMetrics);
  }

  Future<void> _onFetchMetrics(
    FetchMetrics event,
    Emitter<MetricsState> emit,
  ) async {
    emit(MetricsLoading());
    try {
      // 1️⃣ Fetch GraphQL + Search counts
      final result = await githubGraphQL.fetchIntradayMetrics(
        owner: event.owner,
        name: event.repo,
        sinceUtc: event.since.toUtc(),
      );
      if (result.hasException) throw result.exception!;

      final data = result.data!;
      final repo = data['repository'] as Map<String, dynamic>;

      // 2️⃣ Parse commit history
      final history = (((repo['defaultBranchRef'] as Map<String, dynamic>)['target']
              as Map<String, dynamic>)['history'])
          as Map<String, dynamic>;

      final totalCommits = history['totalCount'] as int;
      final nodes = (history['nodes'] as List<dynamic>).cast<Map<String, dynamic>>();

      int additions = 0, deletions = 0;
      final authors = <String>{};

      for (final node in nodes) {
        additions += node['additions'] as int;
        deletions += node['deletions'] as int;
        final user = (node['author']?['user'] as Map?)?['login'] as String?;
        if (user != null) authors.add(user);
      }

      // 3️⃣ Parse star/fork/watcher & languages
      final stars = repo['stargazerCount'] as int;
      final forks = repo['forkCount'] as int;
      final watchers = (repo['watchers'] as Map<String, dynamic>)['totalCount'] as int;

      final edges = (repo['languages'] as Map<String, dynamic>)['edges'] as List<dynamic>;
      final langSizes = <String, int>{};
      int totalSize = 0;
      for (final e in edges.cast<Map<String, dynamic>>()) {
        final name = (e['node'] as Map<String, dynamic>)['name'] as String;
        final size = e['size'] as int;
        langSizes[name] = size;
        totalSize += size;
      }
      final languageBreakdown = langSizes.map((k, v) => MapEntry(k, totalSize > 0 ? v / totalSize : 0.0));

      // 4️⃣ Parse Search counts
      final issuesOpened = (data['issuesOpened'] as Map<String, dynamic>)['issueCount'] as int;
      final issuesClosed = (data['issuesClosed'] as Map<String, dynamic>)['issueCount'] as int;
      final prsOpened = (data['prsOpened'] as Map<String, dynamic>)['issueCount'] as int;
      final prsMerged = (data['prsMerged'] as Map<String, dynamic>)['issueCount'] as int;

      // 5️⃣ REST fallbacks
      final weeklyActivity = await githubRest.fetchWeeklyCommitActivity(
        owner: event.owner,
        repo: event.repo,
      );
      final createEvents = await githubRest.fetchCreateEvents(
        owner: event.owner,
        repo: event.repo,
        since: event.since,
      );

      // 6️⃣ Compose & emit
      final metrics = Metrics(
        commitCount: totalCommits,
        additions: additions,
        deletions: deletions,
        uniqueAuthors: authors.length,
        issuesOpened: issuesOpened,
        issuesClosed: issuesClosed,
        prsOpened: prsOpened,
        prsMerged: prsMerged,
        starCount: stars,
        forkCount: forks,
        watcherCount: watchers,
        languageBreakdown: languageBreakdown,
        weeklyCommitActivity: weeklyActivity,
        createEvents: createEvents,
      );
      emit(MetricsLoaded(metrics: metrics));
    } catch (e) {
      emit(MetricsError(message: e.toString()));
    }
  }
}
