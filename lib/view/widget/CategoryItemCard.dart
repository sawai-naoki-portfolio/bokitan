import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utility/Category.dart';
import '../../utility/Product.dart';
import 'ProductCard.dart';

/// ---------------------------------------------------------------------------
/// CategoryItemCard
/// ─────────────────────────────────────────────────────────
/// このウィジェットは、ドラッグ操作による並び替えが必要な場合に利用するシンプルな
/// カード形式の表示ウィジェットです。タップすると単語の詳細ダイアログを表示します。
/// ---------------------------------------------------------------------------
class CategoryItemCard extends ConsumerWidget {
  final Product product; // 表示対象の単語の情報
  final int index; // リスト内の位置（ドラッグ操作用）
  final Category currentCategory; // 所属するカテゴリ情報

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
        onTap: () => showProductDialog(context, product),
        margin: EdgeInsets.symmetric(
          vertical: context.paddingMedium,
          horizontal: context.paddingMedium,
        ),
      ),
    );
  }
}
