import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initialize();
    return _db!;
  }

  Future<Database> _initialize() async {
    final String path;
    if (Platform.isAndroid || Platform.isIOS) {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'lumi.db');
    } else {
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, 'lumi.db');
    }

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT,
            labels TEXT NOT NULL DEFAULT '[]',
            status TEXT NOT NULL DEFAULT 'todo',
            priority TEXT NOT NULL DEFAULT 'medium',
            deadline INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            completed_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE todos ADD COLUMN completed_at INTEGER');
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE todos ADD COLUMN labels TEXT NOT NULL DEFAULT '[]'",
          );
        }
      },
    );
  }
}
