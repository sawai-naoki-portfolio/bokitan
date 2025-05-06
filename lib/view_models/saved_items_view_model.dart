import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedItemsNotifier extends StateNotifier<List<String>> {
  SavedItemsNotifier() : super([]) {
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    state = saved;
  }

  Future<void> saveItem(String productName) async {
    if (!state.contains(productName)) {
      state = [...state, productName];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_items', state);
    }
  }

  Future<void> removeItem(String productName) async {
    if (state.contains(productName)) {
      state = state.where((e) => e != productName).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_items', state);
    }
  }

  // 新たに並び順を更新するメソッド
  Future<void> reorderItems(List<String> newOrder) async {
    state = newOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_items', state);
  }
}

final savedItemsProvider =
    StateNotifierProvider<SavedItemsNotifier, List<String>>(
        (ref) => SavedItemsNotifier());
