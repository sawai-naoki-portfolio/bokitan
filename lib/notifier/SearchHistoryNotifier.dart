import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('search_history') ?? [];
    state = list;
  }

  Future<void> addProduct(String productName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> newHistory = List.from(state);
    newHistory.remove(productName); // 重複があれば削除
    newHistory.insert(0, productName); // 最新を先頭に追加
    if (newHistory.length > 15) {
      newHistory = newHistory.sublist(0, 15);
    }
    state = newHistory;
    await prefs.setStringList('search_history', state);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', state);
  }
}
