// ============================================================================
// CategoryAssignmentSheet
// -----------------------------------------------------------------------------
// CategoryAssignmentSheet は、指定された商品（Product）に対して、
// ・どのリストに所属させるか（チェックボックスで複数選択可能）
// ・「保存済み」にするかどうか
// の割り当て状態を設定するためのモーダルシートです。
// ============================================================================
import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showCategoryCreationDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/categoriesProvider.dart';
import '../../provider/savedItemsProvider.dart';
import '../../utility/Product.dart';

class CategoryAssignmentSheet extends ConsumerStatefulWidget {
  final Product product;

  /// [product] - リスト割当の対象商品
  const CategoryAssignmentSheet({super.key, required this.product});

  @override
  CategoryAssignmentSheetState createState() => CategoryAssignmentSheetState();
}

// ============================================================================
// CategoryAssignmentSheetState
// -----------------------------------------------------------------------------
// CategoryAssignmentSheetState において、既存のリスト割当情報と
// 保存状態をローカルに保持し、ユーザーがチェックを変更した結果を反映後、
// 「完了」ボタンを押すとそれぞれのプロバイダーに更新を通知します。
// ============================================================================
class CategoryAssignmentSheetState
    extends ConsumerState<CategoryAssignmentSheet> {
  /// 各リスト名と、該当商品がそのリストに所属しているかの状態（trueなら所属）
  late Map<String, bool> _localAssignments;

  /// 商品が「保存単語一覧」に登録されるべきかのローカル状態（初期状態は常に true）
  late bool _localSaved;

  @override
  void initState() {
    super.initState();
    // 既存のリスト割当情報をローカルに初期化
    final currentCategories = ref.read(categoriesProvider);
    _localAssignments = {
      for (var cat in currentCategories)
        cat.name: cat.products.contains(widget.product.name)
    };
    // 初期状態で必ずチェックボックスオンにする
    _localSaved = true;
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
            // ヘッダ部分：対象商品の名称と「新規リスト追加」ボタン
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    "【${widget.product.name}】のリスト割当",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.fontSizeMedium,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final newCat = await showCategoryCreationDialog(context);
                    if (newCat != null && newCat.isNotEmpty) {
                      await ref
                          .read(categoriesProvider.notifier)
                          .addCategory(newCat);
                      setState(() {
                        _localAssignments[newCat] = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("新規リスト追加"),
                ),
              ],
            ),
            const Divider(),
            // ★ ★ 変更箇所 ★ ★
            // 「保存単語一覧」チェックボックスを初期状態 ON で表示し、
            // onChanged ではローカル状態(_localSaved)のみを変更（完了ボタン押下まで更新は行わない）
            CheckboxListTile(
              title: const Text("保存単語一覧"),
              value: _localSaved,
              onChanged: (bool? newVal) {
                setState(() {
                  _localSaved = newVal ?? false;
                });
              },
            ),
            const Divider(),
            // リスト一覧のチェックボックスリスト：各リストにこの商品を割り当てるか選択
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
                    onChanged: (bool? newVal) {
                      setState(() {
                        _localAssignments[cat.name] = newVal ?? false;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // 完了ボタン：押されるまで保存単語一覧への更新は行われない
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                // 各リストへの割当更新
                for (var entry in _localAssignments.entries) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateProductAssignment(
                        entry.key,
                        widget.product.name,
                        entry.value,
                      );
                }
                // 完了ボタン押下時にローカル状態 _localSaved に応じて保存単語一覧を更新
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
