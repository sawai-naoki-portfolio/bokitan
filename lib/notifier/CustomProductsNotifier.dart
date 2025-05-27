import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/Product.dart';

/// ---------------------------------------------------------------------------
/// CustomProductsNotifier
/// ---------------------------------------------------------------------------
/// ユーザーがアプリ上で追加したカスタム単語（Productオブジェクト）のリストを管理する
/// StateNotifier。インスタンス化時に SharedPreferences からデータをロードし、
/// addProduct() で新規単語を追加すると同時にストレージへ保存します。
class CustomProductsNotifier extends StateNotifier<List<Product>> {
  CustomProductsNotifier() : super([]) {
    _loadCustomProducts();
  }

  /// _loadCustomProducts()
  /// SharedPreferences から保存済みのカスタム単語リストを読み込んで状態を初期化する
  Future<void> _loadCustomProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? productJsonList =
        prefs.getStringList('custom_products');
    if (productJsonList != null) {
      state = productJsonList.map((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return Product.fromJson(json);
      }).toList();
    }
  }

  /// addProduct()
  /// 新しいカスタム単語を状態に追加し、最新のリストを SharedPreferences に保存する
  Future<void> addProduct(Product product) async {
    state = [...state, product];
    final prefs = await SharedPreferences.getInstance();
    // 保存する際は、必要なプロパティのみエンコードする
    final productJsonList = state
        .map((p) => jsonEncode({
              'name': p.name,
              'yomigana': p.yomigana,
              'description': p.description,
            }))
        .toList();
    await prefs.setStringList('custom_products', productJsonList);
  }
}
