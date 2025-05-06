import 'package:bookkeeping_vocabulary_notebook/utils/product_card.dart';
import 'package:bookkeeping_vocabulary_notebook/utils/show_product_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

class SavedItemCard extends ConsumerWidget {
  final Product product;
  final int index;

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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
    );
  }
}
