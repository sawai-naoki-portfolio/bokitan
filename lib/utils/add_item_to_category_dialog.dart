import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../view_models/categories_view_model.dart';
import '../view_models/products_view_model.dart';

class AddItemToCategoryDialog extends ConsumerWidget {
  final Category category;

  const AddItemToCategoryDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全商品一覧から、既にカテゴリーに入っていない商品の名前を抽出
    final allProducts = ref.watch(allProductsProvider);
    final availableOptions = allProducts
        .where((p) => !category.products.contains(p.name))
        .map((p) => p.name)
        .toList();

    return AlertDialog(
      title: const Text("商品を追加"),
      content: Autocomplete<String>(
        // 候補の絞り込み（入力に応じて）
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.trim().isEmpty) {
            return availableOptions;
          }
          return availableOptions.where((option) => option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        },
        // ユーザーが候補を選択したタイミング
        onSelected: (String selected) async {
          await ref
              .read(categoriesProvider.notifier)
              .updateProductAssignment(category.name, selected, true);
          Navigator.of(context).pop();
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: "商品を検索",
              border: OutlineInputBorder(),
            ),
            onEditingComplete: onEditingComplete,
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
      ],
    );
  }
}
