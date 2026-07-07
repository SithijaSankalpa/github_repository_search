class SearchHistoryEntry {
  final int? id;
  final String query;
  final DateTime searchedAt;

  SearchHistoryEntry({
    this.id,
    required this.query,
    required this.searchedAt,
});
  Map<String, dynamic> toMap() {
    return {
      if(id != null) 'id': id,
    'query': query,
      'searched_at': searchedAt.millisecondsSinceEpoch,};
    }
    factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      id: map['id'] as int?,
        query: map['query'] as String,
        searchedAt: DateTime.fromMillisecondsSinceEpoch(map['searched_at'] as int),
    );
  }
}