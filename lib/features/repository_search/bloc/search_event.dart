import 'package:equatable/equatable.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchNextPageRequested extends SearchEvent {}

class SearchRefreshed extends SearchEvent {}

class SearchReset extends SearchEvent {}