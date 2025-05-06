import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckedQuestionsNotifier extends StateNotifier<Set<String>> {
  CheckedQuestionsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('checked_questions') ?? [];
    // ロードした結果と既存の state をマージする
    state = state.union(list.toSet());
  }

  Future<void> add(String productName) async {
    if (!state.contains(productName)) {
      state = {...state, productName};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('checked_questions', state.toList());
    }
  }

  Future<void> remove(String productName) async {
    if (state.contains(productName)) {
      state = state.where((name) => name != productName).toSet();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('checked_questions', state.toList());
    }
  }

  Future<void> toggle(String productName) async {
    if (state.contains(productName)) {
      await remove(productName);
    } else {
      await add(productName);
    }
  }
}

final checkedQuestionsProvider =
    StateNotifierProvider<CheckedQuestionsNotifier, Set<String>>(
        (ref) => CheckedQuestionsNotifier());
