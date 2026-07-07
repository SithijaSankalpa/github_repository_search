import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import 'search_history_entry.dart';

class SearchHistoryRepository {
  final DatabaseHelper _dbHelper;
  static const int maxEntries = 20;

  SearchHistoryRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableName,
      SearchHistoryEntry(query: trimmed, searchedAt: DateTime.now()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _enforceMaxEntries(db);
  }

  Future<List<SearchHistoryEntry>> getRecentSearches({int limit = maxEntries}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableName,
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return maps.map((m) => SearchHistoryEntry.fromMap(m)).toList();
  }

  Future<void> deleteSearch(String query) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableName,
      where: 'query = ?',
      whereArgs: [query],
    );
  }

  Future<void> clearHistory() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableName);
  }

  Future<void> _enforceMaxEntries(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableName}'),
    );
    if (count != null && count > maxEntries) {
      final excess = count - maxEntries;
      await db.rawDelete('''
        DELETE FROM ${DatabaseHelper.tableName}
        WHERE id IN (
          SELECT id FROM ${DatabaseHelper.tableName}
          ORDER BY searched_at ASC
          LIMIT $excess
        )
      ''');
    }
  }
}