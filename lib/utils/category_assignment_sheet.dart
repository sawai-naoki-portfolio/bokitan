import 'package:bookkeeping_vocabulary_notebook/utils/show_category_creation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../view_models/categories_view_model.dart';
import '../view_models/saved_items_view_model.dart';

class CategoryAssignmentSheet extends ConsumerStatefulWidget {
  final Product product;

  const CategoryAssignmentSheet({super.key, required this.product});

  @override
  CategoryAssignmentSheetState createState() => CategoryAssignmentSheetState();
}

class CategoryAssignmentSheetState
    extends ConsumerState<CategoryAssignmentSheet> {
  // ローカルで各カテゴリーのチェック状態を保持（キーはカテゴリー名）
  late Map<String, bool> _localAssignments;

  // 「保存した単語一覧」のローカル状態
  late bool _localSaved;

  @override
  void initState() {
    super.initState();
    // 初期状態として、プロバイダーから現在の状態を取得
    // ref.read() は initState 内でも使えます
    final currentCategories = ref.read(categoriesProvider);
    _localAssignments = {
      for (var cat in currentCategories)
        cat.name: cat.products.contains(widget.product.name)
    };
    final currentSaved = ref.read(savedItemsProvider);
    _localSaved = currentSaved.contains(widget.product.name);
  }

  @override
  Widget build(BuildContext context) {
    // 再度カテゴリー一覧を取得（変更があった場合に備える）
    final categories = ref.watch(categoriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル行：左にタイトル、右に「＋新規カテゴリーを追加」ボタン
            Row(
              children: [
                Expanded(
                  child: Text(
                    "【${widget.product.name}】のカテゴリー割当",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final newCat = await showCategoryCreationDialog(context);
                    if (newCat != null && newCat.isNotEmpty) {
                      // 新規カテゴリーを追加
                      await ref
                          .read(categoriesProvider.notifier)
                          .addCategory(newCat);
                      // 新規カテゴリー追加後、ローカル状態にも追加（初期は割当無し）
                      setState(() {
                        _localAssignments[newCat] = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("新規カテゴリーを追加"),
                ),
              ],
            ),
            const Divider(),
            // 保存した単語一覧チェックボックス（ローカル状態で保持）
            CheckboxListTile(
              title: const Text("保存単語"),
              value: _localSaved,
              onChanged: (newVal) {
                setState(() {
                  _localSaved = newVal ?? false;
                });
              },
            ),
            const Divider(),
            // カテゴリーリスト（各カテゴリーのチェック状態もローカル管理）
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  // ローカル状態に存在しない場合は、初期値としてfalseを設定
                  final assigned = _localAssignments[cat.name] ?? false;
                  return CheckboxListTile(
                    title: Text(cat.name),
                    value: assigned,
                    onChanged: (newVal) {
                      setState(() {
                        _localAssignments[cat.name] = newVal ?? false;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // 下部「完了」ボタン：完了ボタンが押されたときにプロバイダーへ更新を反映
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                // 各カテゴリーについてローカル状態をもとに更新
                for (var entry in _localAssignments.entries) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateProductAssignment(
                        entry.key,
                        widget.product.name,
                        entry.value,
                      );
                }
                // 保存状態も更新
                if (_localSaved) {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .saveItem(widget.product.name);
                } else {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(widget.product.name);
                }
                Navigator.pop(context);
              },
              child: const Text(
                "完了",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
