import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

const _itemsKey = 'grocery_items';
const _usersKey = 'grocery_users';
const _settingsKey = 'grocery_settings';

class DatabaseProvider {
  static Future<WebDatabase> database() async {
    return WebDatabase();
  }
}

class WebDatabase {
  Future<List<Map<String, dynamic>>> _readTable(String key) async {
    final raw = html.window.localStorage[key];
    if (raw == null || raw.isEmpty) return [];
    try {
      final jsonData = jsonDecode(raw) as List<dynamic>;
      return jsonData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeTable(String key, List<Map<String, dynamic>> rows) async {
    html.window.localStorage[key] = jsonEncode(rows);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs}) async {
    final rows = await _readTable(_keyFor(table));
    if (where == null || where.isEmpty) return rows;
    var conditions = where.split('AND').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (conditions.length != (whereArgs?.length ?? 0)) return rows;

    return rows.where((row) {
      for (var i = 0; i < conditions.length; i++) {
        final condition = conditions[i];
        final parts = condition.split('=');
        if (parts.length != 2) return false;
        final field = parts[0].trim();
        final matcher = whereArgs?[i]?.toString();
        if (matcher == null) return false;
        if (row[field]?.toString() != matcher) return false;
      }
      return true;
    }).toList();
  }

  Future<void> insert(String table, Map<String, dynamic> value, {dynamic conflictAlgorithm}) async {
    final rows = await _readTable(_keyFor(table));
    final pk = table == 'settings' ? 'key' : 'id';
    rows.removeWhere((row) => row[pk] == value[pk]);
    rows.add(value);
    await _writeTable(_keyFor(table), rows);
  }

  Future<void> update(String table, Map<String, dynamic> value, {required String where, required List<Object?> whereArgs}) async {
    final rows = await query(table, where: where, whereArgs: whereArgs);
    if (rows.isEmpty) return;
    final allRows = await _readTable(_keyFor(table));
    for (var i = 0; i < allRows.length; i++) {
      if (allRows[i]['id'] == rows.first['id']) {
        allRows[i] = value;
        break;
      }
    }
    await _writeTable(_keyFor(table), allRows);
  }

  Future<void> delete(String table, {required String where, required List<Object?> whereArgs}) async {
    final allRows = await _readTable(_keyFor(table));
    final parts = where.split('=');
    if (parts.length != 2) return;
    final field = parts[0].trim();
    final matcher = whereArgs.first?.toString();
    allRows.removeWhere((row) => row[field]?.toString() == matcher);
    await _writeTable(_keyFor(table), allRows);
  }

  String _keyFor(String table) {
    if (table == 'users') return _usersKey;
    if (table == 'settings') return _settingsKey;
    return _itemsKey;
  }
}
