import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String tableName = 'search_history';

  Future<Database> get database async {
    _database ??=await _initDatabase();
    return _database!;
  }
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'github_search.db');

    return openDatabase(path, version: 1, onCreate: (db,version) async
    {
      await db.execute(
          "CREATE TABLE $tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, query TEXT NOT NULL UNIQUE,searched_at INTEGER NOT NULL)"
      );
    },
    );
  }
}