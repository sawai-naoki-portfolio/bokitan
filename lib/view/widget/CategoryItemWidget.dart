
import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/categoriesProvider.dart';
import '../../utility/Category.dart';
import '../../utility/Product.dart';

/// ---------------------------------------------------------------------------
/// CategoryItemWidget
/// ─────────────────────────────────────────────────────────
/// このウィジェットは、1件のカテゴリ内単語をリスト表示する際に利用します。
/// ・スワイプで削除（確認ダイアログ付き）
/// ・長押しで削除確認のダイアログを個別に表示
/// ・ドラッグ＆ドロップによる並び替えハンドルを提供
/// ---------------------------------------------------------------------------
class CategoryItemWidget extends ConsumerWidget {
  final Product product; // 表示する対象単語
  final int index; // リスト内のインデックス
  final Category currentCategory; // 現在のカテゴリ情報

  const CategoryItemWidget({
    super.key,
    required this.product,
    required this.index,
    required this.currentCategory,
  });

  /// [_deleteItem]
  /// ─────────────────────────────────────────────────────────
  /// 長押し時に呼び出される削除確認ダイアログを表示するメソッドです。
  /// ユーザーが削除を承認した場合、対象カテゴリからこの単語を除去します。
  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("削除確認"),
          content: Text("${product.name} を削除してよろしいですか？"),
          actions: [
            // キャンセルボタン：何もせず閉じる
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("キャンセル"),
            ),
            // 削除ボタン：削除処理を実行
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

  /// [build]
  /// ─────────────────────────────────────────────────────────
  /// スワイプ（Dismissible）と長押し（GestureDetector）による操作が統合されたカード型ウィジェットを返します。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(product.name),
      direction: DismissDirection.endToStart,
      // 右端から左端へのスワイプで削除
      confirmDismiss: (direction) async {
        // スワイプ時も削除確認ダイアログを表示
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("削除確認"),
              content: Text("${product.name} を削除してよろしいですか？"),
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
        padding: EdgeInsets.symmetric(horizontal: context.paddingMedium),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // スワイプ完了後に削除処理を呼び出す
      onDismissed: (direction) async {
        await ref
            .read(categoriesProvider.notifier)
            .updateProductAssignment(currentCategory.name, product.name, false);
      },
      // 長押しで個別の削除ダイアログを起動
      child: GestureDetector(
        onLongPress: () async {
          await _deleteItem(context, ref);
        },
        child: Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(
            vertical: context.paddingMedium,
            horizontal: context.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // 並び替え開始ハンドルの提供
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.fontSizeMedium,
              ),
            ),
            subtitle: Text(
              product.description,
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
            onTap: () => showProductDialog(context, product),
          ),
        ),
      ),
    );
  }
}