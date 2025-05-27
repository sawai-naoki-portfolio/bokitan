// ============================================================================
// MistakeCountNotifier
// -----------------------------------------------------------------------------
// この StateNotifier は、各単語（Product）のミス回数（誤答回数）の累計を
// Map<String, int> 型で管理します。
// ・初期化時に SharedPreferences から以前のミスカウントをロードします。
// ・increment メソッドで指定された単語のミス数を増加させ、その値を保存します。
// ============================================================================
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MistakeCountNotifier extends StateNotifier<Map<String, int>> {
  MistakeCountNotifier() : super({}) {
    _loadCounts();
  }

  // SharedPreferences からミス回数の記録をロード
  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mistake_counts');
    if (data != null) {
      state = Map<String, int>.from(jsonDecode(data));
    }
  }

  // 指定された単語のミス回数を増加させ、結果を永続化する
  Future<void> increment(String productName) async {
    final current = state[productName] ?? 0;
    state = {...state, productName: current + 1};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mistake_counts', jsonEncode(state));
  }
}
