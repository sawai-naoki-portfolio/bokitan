import 'package:shared_preferences/shared_preferences.dart';

import 'Product.dart';

/// ---------------------------------------------------------------------------
/// loadMemo
/// ─ SharedPreferencesから指定されたProductに対応するメモを読み込む
/// ---------------------------------------------------------------------------
Future<String> loadMemo(Product product) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('memo_${product.name}') ?? "";
}
