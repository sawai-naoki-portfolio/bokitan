import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Material3Notifier extends StateNotifier<bool> {
  Material3Notifier() : super(false) {
    _loadMaterial3();
  }

  // SharedPreferencesからMaterial3の利用設定を読み込む
  Future<void> _loadMaterial3() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('use_material3') ?? false;
    state = isEnabled;
  }

  // Material3の利用設定を更新し、SharedPreferencesにも保存する
  Future<void> setMaterial3(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_material3', value);
  }
}
