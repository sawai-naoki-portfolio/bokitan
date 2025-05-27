
import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utility/Product.dart';
import 'ProductCard.dart';

/// ---------------------------------------------------------------------------
/// SavedItemCard
/// ─────────────────────────────────────────────────────────
/// 保存済み（お気に入りなど）の単語のカード表示ウィジェットです。
/// CategoryItemCard と非常に似ていますが、主に保存された単語の一覧表示で用いられます。
/// ---------------------------------------------------------------------------
class SavedItemCard extends ConsumerWidget {
  final Product product; // 表示対象の単語の情報
  final int index; // 保存リスト内のインデックス

  const SavedItemCard({
    super.key,
    required this.product,
    required this.index,
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
