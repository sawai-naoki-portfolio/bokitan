import 'package:flutter/material.dart';

import '../models/product.dart';

class CommonProductListView extends StatelessWidget {
  /// 表示する商品のリスト
  final List<Product> products;

  /// 各アイテムのウィジェットを生成するためのビルダー
  final Widget Function(BuildContext context, Product product) itemBuilder;

  /// プル・トゥ・リフレッシュ処理（オプション）
  final Future<void> Function()? onRefresh;

  /// 並び替え可能な表示にする際のフラグ
  final bool isReorderable;

  /// 並び替え時のコールバック（trueの場合は必須）
  final void Function(int oldIndex, int newIndex)? onReorder;

  const CommonProductListView({
    super.key,
    required this.products,
    required this.itemBuilder,
    this.onRefresh,
    this.isReorderable = false,
    this.onReorder,
  }) : assert(!isReorderable || onReorder != null,
            'Reorderableの場合、onReorderは必須です');

  @override
  Widget build(BuildContext context) {
    // 並び替えが有効であればReorderableListViewを利用
    Widget list;
    if (isReorderable) {
      list = ReorderableListView.builder(
        itemCount: products.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final product = products[index];
          // ReorderableListViewでは各アイテムにKeyが必要
          return Container(
            key: ValueKey(product.name),
            child: itemBuilder(context, product),
          );
        },
      );
    } else {
      list = ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return itemBuilder(context, products[index]);
        },
      );
    }

    // RefreshIndicatorが設定されていればラップして返す
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }
}
