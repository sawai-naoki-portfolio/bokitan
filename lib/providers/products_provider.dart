import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

/// JSONファイルから単語データを読み込むProvider
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await rootBundle.loadString('assets/products.json');
  final jsonResult = jsonDecode(data) as List;
  return jsonResult.map((json) => Product.fromJson(json)).toList();
});
