import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../view_models/categories_view_model.dart';
import '../show_product_dialog.dart';

class CategoryItemWidget extends ConsumerWidget {
  final Product product;
  final int index;
  final Category currentCategory;

  const CategoryItemWidget({
    super.key,
    required this.product,
    required this.index,
    required this.currentCategory,
  });

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("削除確認"),
          content: Text("${product.name} を削除しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("削除"),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await ref
          .read(categoriesProvider.notifier)
          .updateProductAssignment(currentCategory.name, product.name, false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(product.name),
      direction: DismissDirection.endToStart,
      // confirmDismiss で左スワイプによる削除の前に確認ダイアログを表示
      confirmDismiss: (direction) async {
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("削除確認"),
              content: Text("${product.name} を削除しますか？"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("キャンセル"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("削除"),
                ),
              ],
            );
          },
        );
        return result ?? false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await ref
            .read(categoriesProvider.notifier)
            .updateProductAssignment(currentCategory.name, product.name, false);
      },
      child: GestureDetector(
        // 長押し時にも同様の削除確認ダイアログを表示
        onLongPress: () async {
          await _deleteItem(context, ref);
        },
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // 左側にドラッグハンドル（二点ボタン）を配置
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              product.description,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () => showProductDialog(context, product),
          ),
        ),
      ),
    );
  }
}
