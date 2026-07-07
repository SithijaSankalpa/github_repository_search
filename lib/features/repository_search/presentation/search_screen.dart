import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../../repo_detail/presentation/repo_detail_screen.dart';
import '../../token/bloc/token_cubit.dart';
import '../../token/presentation/token_screen.dart';
import '../../search_history/bloc/search_history_cubit.dart';
import '../../search_history/bloc/search_history_state.dart';
import '../../../core/theme/theme_cubit.dart';
import 'widgets/repo_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool get _showHistory => _controller.text.isEmpty;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goToTokenScreen(BuildContext context) {
    context.read<SearchBloc>().add(SearchReset());
    context.read<TokenCubit>().clearToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TokenScreen()),
          (route) => false,
    );
  }

  void _runSearch(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    context.read<SearchBloc>().add(SearchQueryChanged(query));
    _focusNode.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repo Search'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Clear token',
            onPressed: () => _goToTokenScreen(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (value) {
                context.read<SearchBloc>().add(SearchQueryChanged(value));
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search GitHub repositories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    context.read<SearchBloc>().add(const SearchQueryChanged(''));
                    setState(() {});
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _showHistory
                ? _SearchHistoryPanel(onSelect: _runSearch)
                : BlocListener<SearchBloc, SearchState>(
              listener: (context, state) {
                if (state is SearchLoaded && state.currentPage == 1) {
                  context.read<SearchHistoryCubit>().recordSearch(state.query);
                }
              },
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  return switch (state) {
                    SearchInitial() => const _CenteredMessage(
                      icon: Icons.explore_outlined,
                      text: 'Search for a repository to get started',
                    ),
                    SearchLoading() =>
                    const Center(child: CircularProgressIndicator()),
                    SearchEmpty() => const _CenteredMessage(
                      icon: Icons.search_off,
                      text: 'No results found',
                    ),
                    SearchUnauthorized() => _UnauthorizedView(
                      onRetry: () =>
                          context.read<SearchBloc>().add(SearchRefreshed()),
                      onReenterToken: () => _goToTokenScreen(context),
                    ),
                    SearchError(:final message) => _ErrorView(
                      message: message,
                      onRetry: () =>
                          context.read<SearchBloc>().add(SearchRefreshed()),
                    ),
                    SearchLoaded(
                        :final results,
                        :final hasReachedMax,
                        :final isLoadingMore
                    ) =>
                        _ResultsList(
                          results: results,
                          hasReachedMax: hasReachedMax,
                          isLoadingMore: isLoadingMore,
                        ),
                  };
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHistoryPanel extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _SearchHistoryPanel({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchHistoryCubit, SearchHistoryState>(
      builder: (context, state) {
        final entries = state is SearchHistoryLoaded ? state.entries : const [];

        if (entries.isEmpty) {
          return const _CenteredMessage(
            icon: Icons.history,
            text: 'No recent searches yet',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent searches',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<SearchHistoryCubit>().clearAll();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(entry.query),
                    onTap: () => onSelect(entry.query),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        context.read<SearchHistoryCubit>().deleteEntry(entry.query);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List results;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const _ResultsList({
    required this.results,
    required this.hasReachedMax,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SearchBloc>().add(SearchRefreshed());
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          final nearBottom = scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent - 300;
          if (nearBottom && !hasReachedMax && !isLoadingMore) {
            context.read<SearchBloc>().add(SearchNextPageRequested());
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: results.length + (hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= results.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final repo = results[index];
            return RepoListItem(
              repo: repo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RepoDetailScreen(repo: repo)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnauthorizedView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onReenterToken;

  const _UnauthorizedView({required this.onRetry, required this.onReenterToken});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Your token is invalid or has expired.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onReenterToken,
                  child: const Text('Re-enter Token'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CenteredMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}