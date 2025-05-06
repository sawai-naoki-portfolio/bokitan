import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../product_card.dart';
import '../show_product_dialog.dart';

class CategoryItemCard extends ConsumerWidget {
  final Product product;
  final int index;
  final Category currentCategory;

  const CategoryItemCard({
    super.key,
    required this.product,
    required this.index,
    required this.currentCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: ProductCard(
        product: product,
        // onTapは商品詳細ダイアログを表示する既存の処理を流用
        onTap: () => showProductDialog(context, product),
        // ProductCardの見た目は SearchPage と同じUI（CircleAvatar, タイトル, サブタイトル）
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
    );
  }
}
