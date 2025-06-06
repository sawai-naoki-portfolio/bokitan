// ============================================================================
// AddItemToCategoryDialog
// -----------------------------------------------------------------------------
// このウィジェットは、「カテゴリ内に新たに単語を追加」するためのダイアログです。
// ・全単語の中から、既にそのカテゴリに登録されていない商品を対象に自動補完（Autocomplete）で検索
// ・ユーザーが候補をタップすると、該当リストに自動で商品が追加されます。
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/allProductsProvider.dart';
import '../../provider/categoriesProvider.dart';
import '../../utility/Category.dart';

class AddItemToCategoryDialog extends ConsumerWidget {
  final Category category;

  /// [category] - 商品を追加する対象のリスト情報
  const AddItemToCategoryDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全単語を取得し、既にカテゴリに含まれていない商品の名前リストを作成
    final allProducts = ref.watch(allProductsProvider);
    final availableOptions = allProducts
        .where((p) => !category.products.contains(p.name))
        .map((p) => p.name)
        .toList();

    return AlertDialog(
      title: const Text("単語を追加"),
      content: Autocomplete<String>(
        // 入力に応じた候補リストを生成
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.trim().isEmpty) {
            return availableOptions;
          }
          return availableOptions.where((option) => option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        },
        // ユーザーが候補を選択したとき：該当商品のカテゴリ割当を更新しダイアログを閉じる
        onSelected: (String selected) async {
          await ref.read(categoriesProvider.notifier).updateProductAssignment(
                category.name,
                selected,
                true,
              );
          if (!context.mounted) return;
          Navigator.of(context).pop();
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: "単語を検索",
              border: OutlineInputBorder(),
            ),
            onEditingComplete: onEditingComplete,
          );
        },
      ),
      actions: [
        // キャンセルボタン：何もせずダイアログを閉じる
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
      ],
    );
  }
}
