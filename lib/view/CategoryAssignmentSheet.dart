// ============================================================================
// CategoryAssignmentSheet
// -----------------------------------------------------------------------------
// CategoryAssignmentSheet は、指定された商品（Product）に対して、
// ・どのカテゴリーに所属させるか（チェックボックスで複数選択可能）
// ・「保存済み」にするかどうか
// の割り当て状態を設定するためのモーダルシートです。
// ============================================================================
import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showCategoryCreationDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/categoriesProvider.dart';
import '../provider/savedItemsProvider.dart';
import '../utility/Product.dart';

class CategoryAssignmentSheet extends ConsumerStatefulWidget {
  final Product product;

  /// [product] - カテゴリー割当の対象商品
  const CategoryAssignmentSheet({super.key, required this.product});

  @override
  CategoryAssignmentSheetState createState() => CategoryAssignmentSheetState();
}

// ============================================================================
// CategoryAssignmentSheetState
// -----------------------------------------------------------------------------
// CategoryAssignmentSheetState において、既存のカテゴリー割当情報と
// 保存状態をローカルに保持し、ユーザーがチェックを変更した結果を反映後、
// 「完了」ボタンを押すとそれぞれのプロバイダーに更新を通知します。
// ============================================================================
class CategoryAssignmentSheetState
    extends ConsumerState<CategoryAssignmentSheet> {
  /// 各カテゴリー名と、該当商品がそのカテゴリーに所属しているかの状態（trueなら所属）
  late Map<String, bool> _localAssignments;

  /// 商品が「保存単語」（お気に入り）に登録されているかの状態
  late bool _localSaved;

  @override
  void initState() {
    super.initState();
    // 現在のカテゴリー割当情報をローカル状態として初期化
    final currentCategories = ref.read(categoriesProvider);
    _localAssignments = {
      for (var cat in currentCategories)
        cat.name: cat.products.contains(widget.product.name)
    };
    // 保存状態についても初期値を設定
    final currentSaved = ref.read(savedItemsProvider);
    _localSaved = currentSaved.contains(widget.product.name);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダ部分：対象商品の名称と「新規カテゴリー追加」ボタン
            Row(
              children: [
                Expanded(
                  child: Text(
                    "【${widget.product.name}】のカテゴリー割当",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.fontSizeMedium,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    // 新しいカテゴリーを追加するダイアログを表示
                    final newCat = await showCategoryCreationDialog(context);
                    if (newCat != null && newCat.isNotEmpty) {
                      await ref
                          .read(categoriesProvider.notifier)
                          .addCategory(newCat);
                      setState(() {
                        // 新規追加したカテゴリーは初期状態で未割当にする
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
            // 「保存単語」チェックボックス：お気に入り登録のオン／オフ
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
            // カテゴリー一覧のチェックボックスリスト：各カテゴリーにこの商品を割り当てるか選択
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
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
            // 完了ボタン：選択内容をすべて保存し、ダイアログを閉じる
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                // 各カテゴリーについて、ローカル状態に応じて商品割当の更新を実行
                for (var entry in _localAssignments.entries) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateProductAssignment(
                        entry.key,
                        widget.product.name,
                        entry.value,
                      );
                }

                // 保存状態についても、該当プロバイダーに反映する
                if (_localSaved) {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .saveItem(widget.product.name);
                } else {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(widget.product.name);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(
                "完了",
                style: TextStyle(fontSize: context.fontSizeMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
