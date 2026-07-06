import 'package:equatable/equatable.dart';
import 'package:github_repository_search/features/repository_search/data/models/repository_model.dart';

sealed class SearchState extends Equatable{
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<RepositoryModel> results;
  final bool hasReachedMax;
  final int currentPage;
  final String query;
  final bool isLoadingMore;

  const SearchLoaded ({
    required this.results,
    required this.hasReachedMax,
    required this.currentPage,
    required this.query,
    this.isLoadingMore = false,
});
  SearchLoaded copyWith({
    List<RepositoryModel>?results,
    bool?hasReachedMax,
    int? currentPage,
    String? query,
    bool?isLoadingMore,
}) {
    return SearchLoaded(
      results: results ?? this.results,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      query: query ?? this.query,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
  @override
  List<Object?> get props => [results,hasReachedMax,currentPage, query, isLoadingMore];
}

class SearchEmpty extends SearchState{}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}