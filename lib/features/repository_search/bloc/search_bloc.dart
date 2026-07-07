import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../data/repository_search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final RepositorySearchRepository repository;
  static const int perPage = 20;
  static const Duration debounceDuration = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  String _lastQuery = ''; // remembered independently of current state, so retry always works

  SearchBloc(this.repository) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchNextPageRequested>(_onNextPageRequested);
    on<SearchRefreshed>(_onRefreshed);
    on<SearchReset>(_onReset);
  }

  Future<void> _onQueryChanged(
      SearchQueryChanged event,
      Emitter<SearchState> emit,
      ) async {
    final query = event.query.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    final completer = Completer<void>();
    _debounceTimer = Timer(debounceDuration, () {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    if (emit.isDone) return;

    _lastQuery = query;
    emit(SearchLoading());
    await _performSearch(query: query, page: 1, emit: emit);
  }

  Future<void> _onRefreshed(
      SearchRefreshed event,
      Emitter<SearchState> emit,
      ) async {
    if (_lastQuery.isEmpty) return;
    emit(SearchLoading());
    await _performSearch(query: _lastQuery, page: 1, emit: emit);
  }

  Future<void> _onNextPageRequested(
      SearchNextPageRequested event,
      Emitter<SearchState> emit,
      ) async {
    final current = state;
    if (current is! SearchLoaded || current.hasReachedMax || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.currentPage + 1;
      final more = await repository.search(
        query: current.query,
        page: nextPage,
        perPage: perPage,
      );
      emit(current.copyWith(
        results: [...current.results, ...more],
        hasReachedMax: more.length < perPage,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } on UnauthorizedException {
      emit(SearchUnauthorized());
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  void _onReset(SearchReset event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    _lastQuery = '';
    emit(SearchInitial());
  }

  Future<void> _performSearch({
    required String query,
    required int page,
    required Emitter<SearchState> emit,
  }) async {
    try {
      final results = await repository.search(query: query, page: page, perPage: perPage);
      if (results.isEmpty) {
        emit(SearchEmpty());
      } else {
        emit(SearchLoaded(
          results: results,
          hasReachedMax: results.length < perPage,
          currentPage: page,
          query: query,
        ));
      }
    } on UnauthorizedException {
      emit(SearchUnauthorized());
    } catch (e) {
      emit(SearchError(_messageFor(e)));
    }
  }

  String _messageFor(Object e) {
    if (e is ApiException) return e.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}