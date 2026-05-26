// ignore_for_file: unused_import
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class GroceryStorage {
  static const _dbName = 'grocery.db';
  static const _itemsTable = 'items';

  Database? _db;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $_itemsTable(
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
    });
    return _db!;
  }

  Future<List<GroceryItem>> readItems(String userId) async {
    final db = await _openDb();
    final rows = await db.query(_itemsTable, 
      where: 'userId = ?', 
      whereArgs: [userId],
      orderBy: 'date DESC'
    );
    return rows.map((r) => GroceryItem.fromJson(r)).toList();
  }

  Future<void> insertItem(GroceryItem item) async {
    final db = await _openDb();
    await db.insert(_itemsTable, item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(GroceryItem item) async {
    final db = await _openDb();
    await db.update(_itemsTable, item.toJson(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(String id) async {
    final db = await _openDb();
    await db.delete(_itemsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Backwards-compatible methods used by main.dart
  Future<String?> readData(String userId) async {
    final items = await readItems(userId);
    if (items.isEmpty) return null;
    final list = items.map((i) => i.toJson()).toList();
    return jsonEncode(list);
  }

  Future<void> writeData(String data) async {
    // Accepts a JSON array string and replaces items in the DB.
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      final db = await _openDb();
      await db.transaction((txn) async {
        await txn.delete(_itemsTable);
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item as Map);
          await txn.insert(_itemsTable, map);
        }
      });
    } catch (_) {
      // ignore malformed data
    }
  }
}
