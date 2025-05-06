import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MistakeCountNotifier extends StateNotifier<Map<String, int>> {
  MistakeCountNotifier() : super({}) {
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mistake_counts');
    if (data != null) {
      state = Map<String, int>.from(jsonDecode(data));
    }
  }

  Future<void> increment(String productName) async {
    final current = state[productName] ?? 0;
    state = {...state, productName: current + 1};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mistake_counts', jsonEncode(state));
  }
}

final mistakeCountsProvider =
    StateNotifierProvider<MistakeCountNotifier, Map<String, int>>(
  (ref) => MistakeCountNotifier(),
);
