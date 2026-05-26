import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseProvider {
  static const _dbName = 'grocery.db';
  static Database? _db;

  static Future<Database> database() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE items(
          id TEXT PRIMARY KEY,
          userId TEXT,
          name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT,
          price REAL NOT NULL,
          date TEXT NOT NULL,
          imagePath TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE users(
          id TEXT PRIMARY KEY,
          email TEXT,
          phone TEXT,
          displayName TEXT,
          photoUrl TEXT,
          provider TEXT,
          passwordHash TEXT,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE settings(
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      // Migration: import legacy JSON file if present
      try {
        final legacy = File(join(dir.path, 'grocery_data.json'));
        if (await legacy.exists()) {
          final contents = await legacy.readAsString();
          final data = jsonDecode(contents) as List<dynamic>;
          for (final item in data) {
            final map = Map<String, dynamic>.from(item as Map);
            if (map.containsKey('id') && map.containsKey('date')) {
              await db.insert('items', map, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          try {
            await legacy.delete();
          } catch (_) {}
        }
      } catch (_) {}
    });
    return _db!;
  }
}
