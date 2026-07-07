import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/presentation/splash_screen.dart';
import 'features/token/data/token_repository.dart';
import 'features/token/bloc/token_cubit.dart';
import 'features/repository_search/data/repository_search_repository.dart';
import 'features/repository_search/bloc/search_bloc.dart';
import 'features/search_history/bloc/search_history_cubit.dart';
import 'features/search_history/data/search_history_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenRepository = TokenRepository();
    final apiClient = ApiClient(getToken: tokenRepository.getToken);
    final searchRepository = RepositorySearchRepository(apiClient);
    final searchHistoryRepository = SearchHistoryRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TokenCubit(tokenRepository)..loadToken()),
        BlocProvider(create: (_) => SearchBloc(searchRepository)),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => SearchHistoryCubit(searchHistoryRepository)..loadHistory()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'GitHub Repo Search',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}