import 'package:equatable/equatable.dart';
import '../data/search_history_entry.dart';

sealed class SearchHistoryState extends Equatable {
  const SearchHistoryState();
  @override
  List<Object?> get props => [];
}

class SearchHistoryLoading extends SearchHistoryState {}

class SearchHistoryLoaded extends SearchHistoryState {
  final List<SearchHistoryEntry> entries;
  const SearchHistoryLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}