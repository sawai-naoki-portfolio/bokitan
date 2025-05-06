import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';

class CustomProductsNotifier extends StateNotifier<List<Product>> {
  CustomProductsNotifier() : super([]) {
    _loadCustomProducts();
  }

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

  Future<void> addProduct(Product product) async {
    state = [...state, product];
    final prefs = await SharedPreferences.getInstance();
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

final customProductsProvider =
    StateNotifierProvider<CustomProductsNotifier, List<Product>>(
        (ref) => CustomProductsNotifier());

final allProductsProvider = Provider<List<Product>>((ref) {
  final assetProductsAsync = ref.watch(productsProvider);
  final customProducts = ref.watch(customProductsProvider);
  List<Product> assetProducts = [];

  // assets側のデータが読み込まれている場合のみ統合
  assetProductsAsync.when(
    data: (products) => assetProducts = products,
    loading: () {},
    error: (_, __) {},
  );
  return [...assetProducts, ...customProducts];
});
