import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'models.dart';

class GroceryStorage {
  static const _key = 'grocery_data';

  Future<String?> readData() async {
    return html.window.localStorage[_key];
  }

  Future<void> writeData(String data) async {
    html.window.localStorage[_key] = data;
  }

  Future<List<GroceryItem>> readItems(String userId) async {
    final contents = await readData();
    if (contents == null || contents.isEmpty) return [];
    try {
      final jsonData = jsonDecode(contents) as List<dynamic>;
      final allItems = jsonData.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)).toList();
      return allItems.where((i) => i.userId == userId).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(List<GroceryItem> items) async {
    final jsonData = jsonEncode(items.map((i) => i.toJson()).toList());
    await writeData(jsonData);
  }

  Future<void> insertItem(GroceryItem item) async {
    // Load ALL items first.
    final contents = await readData();
    List<GroceryItem> allItems = [];
    if (contents != null && contents.isNotEmpty) {
      try {
        final jsonData = jsonDecode(contents) as List<dynamic>;
        allItems = jsonData.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    
    allItems.removeWhere((i) => i.id == item.id);
    allItems.insert(0, item);
    await _saveList(allItems);
  }

  Future<void> updateItem(GroceryItem item) async {
    final contents = await readData();
    if (contents == null || contents.isEmpty) return;
    try {
      final jsonData = jsonDecode(contents) as List<dynamic>;
      final allItems = jsonData.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)).toList();
      final idx = allItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        allItems[idx] = item;
        await _saveList(allItems);
      }
    } catch (_) {}
  }

  Future<void> deleteItem(String id) async {
    final contents = await readData();
    if (contents == null || contents.isEmpty) return;
    try {
      final jsonData = jsonDecode(contents) as List<dynamic>;
      final allItems = jsonData.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)).toList();
      allItems.removeWhere((i) => i.id == id);
      await _saveList(allItems);
    } catch (_) {}
  }
}
