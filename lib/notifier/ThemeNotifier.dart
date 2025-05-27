import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  // SharedPreferencesから "theme_mode" キーで保存されたテーマを読み込む
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString("theme_mode") ?? "light";
    if (themeStr == "system") {
      state = ThemeMode.system;
    } else if (themeStr == "dark") {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  // テーマ変更時に SharedPreferences へ保存も行う
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    // シンプルに文字列として保存します（"light", "dark", "system"）
    String modeStr;
    if (mode == ThemeMode.system) {
      modeStr = "system";
    } else if (mode == ThemeMode.dark) {
      modeStr = "dark";
    } else {
      modeStr = "light";
    }
    await prefs.setString("theme_mode", modeStr);
  }

  // 現在の状態が light なら dark に、そうでなければ light に切り替える
  // （system 状態の場合は light に切り替えます）
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.light);
    }
  }
}
