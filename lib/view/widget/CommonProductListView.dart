import 'package:flutter/material.dart';

import '../../utility/Product.dart';

///////////////////////////////////////////////////////////////
// CommonProductListView
///////////////////////////////////////////////////////////////
/// [CommonProductListView] は、Product のリスト表示を共通化するためのウィジェットです。
/// ユーザーの入力によるリフレッシュ機能（onRefresh）や、ドラッグ＆ドロップによる
/// アイテム順序変更（isReorderable / onReorder）もサポートします。
///
/// ・products: 表示対象となる Product のリスト
/// ・itemBuilder: 各 Product を表示するためのウィジェットを構築する関数
/// ・onRefresh: 引っ張って更新する際のコールバック（任意）
/// ・isReorderable: 並び替え可能なリストとする場合は true、必ず onReorder コールバックが必要
class CommonProductListView extends StatelessWidget {
  final List<Product> products;
  final Widget Function(BuildContext context, Product product) itemBuilder;
  final Future<void> Function()? onRefresh;
  final bool isReorderable;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const CommonProductListView({
    super.key,
    required this.products,
    required this.itemBuilder,
    this.onRefresh,
    this.isReorderable = false,
    this.onReorder,
  }) : assert(!isReorderable || onReorder != null,
            'Reorderable の場合、onReorder コールバックは必須です。');

  @override
  Widget build(BuildContext context) {
    Widget list;
    if (isReorderable) {
      list = ReorderableListView.builder(
        itemCount: products.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final product = products[index];
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
    // onRefresh が設定されている場合、RefreshIndicator でラップする
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }
}
