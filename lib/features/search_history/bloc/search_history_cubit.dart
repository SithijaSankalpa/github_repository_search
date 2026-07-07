import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/search_history_repository.dart';
import 'search_history_state.dart';

class SearchHistoryCubit extends Cubit<SearchHistoryState> {
  final SearchHistoryRepository repository;

  SearchHistoryCubit(this.repository) : super(SearchHistoryLoading());

  Future<void> loadHistory() async {
    final entries = await repository.getRecentSearches();
    emit(SearchHistoryLoaded(entries));
  }

  Future<void> recordSearch(String query) async {
    await repository.addSearch(query);
    await loadHistory();
  }

  Future<void> deleteEntry(String query) async {
    await repository.deleteSearch(query);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await repository.clearHistory();
    await loadHistory();
  }
}