import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]) {
    _loadCategories();
  }

  Future<void> reorderProducts(
      String categoryName, int oldIndex, int newIndex) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        List<String> newProducts = List.from(c.products);
        // ここでの newIndex の補正処理は削除する（UI 側で処理済み）
        final item = newProducts.removeAt(oldIndex);
        newProducts.insert(newIndex, item);
        return Category(name: c.name, products: newProducts);
      }
      return c;
    }).toList();
    await _saveCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('saved_categories');
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => Category.fromJson(e)).toList();
    } else {
      state = [];
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((c) => c.toJson()).toList());
    await prefs.setString('saved_categories', data);
  }

  Future<void> addCategory(String name) async {
    if (state.any((c) => c.name == name)) return;
    final newCategory = Category(name: name);
    state = [...state, newCategory];
    await _saveCategories();
  }

  Future<void> updateCategory(String oldName, String newName) async {
    state = state.map((c) {
      if (c.name == oldName) {
        return Category(name: newName, products: c.products);
      }
      return c;
    }).toList();
    await _saveCategories();
  }

  Future<void> deleteCategory(String name) async {
    state = state.where((c) => c.name != name).toList();
    await _saveCategories();
  }

  /// 並び替え処理
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    List<Category> updated = List.from(state);
    // ここでは newIndex の補正処理は不要です
    final Category item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    await _saveCategories();
  }

  /// 指定のカテゴリに対して、単語所属の更新
  Future<void> updateProductAssignment(
      String categoryName, String productName, bool assigned) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        List<String> updatedProducts = List.from(c.products);
        if (assigned) {
          if (!updatedProducts.contains(productName)) {
            updatedProducts.add(productName);
          }
        } else {
          updatedProducts.remove(productName);
        }
        return Category(name: c.name, products: updatedProducts);
      }
      return c;
    }).toList();
    await _saveCategories();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
        (ref) => CategoriesNotifier());
