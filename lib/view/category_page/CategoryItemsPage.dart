import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/allProductsProvider.dart';
import '../../provider/categoriesProvider.dart';
import '../../provider/checkedQuestionsProvider.dart';
import '../../utility/Category.dart';
import '../../utility/Product.dart';
import '../../utility/SwipeToDeleteCard.dart';
import 'CategoryAssignmentSheet.dart';



class CategoryItemsPage extends ConsumerStatefulWidget {
  final Category category;

  const CategoryItemsPage({super.key, required this.category});

  @override
  CategoryItemsPageState createState() => CategoryItemsPageState();
}

/// ---------------------------------------------------------------------------
/// CategoryItemsPageState
/// ─────────────────────────────────────────────────────────
/// カテゴリ内に属する単語の一覧ページを管理する状態クラスです。
/// 画面表示モードとして通常リストと並び替え用のリストを切り替えて表示します。
/// ---------------------------------------------------------------------------
class CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  bool _isSorting = false; // 並び替えモードか通常表示かのフラグ

  @override
  Widget build(BuildContext context) {
    // Riverpodから全カテゴリと全単語の状態を取得し、現在のカテゴリを特定
    final allCategories = ref.watch(categoriesProvider);
    final currentCategory = allCategories.firstWhere(
      (cat) => cat.name == widget.category.name,
      orElse: () => widget.category,
    );
    final allProducts = ref.watch(allProductsProvider);

    // 現在のカテゴリに属する単語のリストを、プロダクト名をキーにして抽出
    final filtered = currentCategory.products.map((productName) {
      return allProducts.firstWhere((p) => p.name == productName);
    }).toList();

    final categoryName = currentCategory.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("リスト: $categoryName"),
        centerTitle: true,
        actions: [
          if (_isSorting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // 並び替えモード終了のためのチェックボタン
                setState(() {
                  _isSorting = false;
                });
              },
            )
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("このリストに単語はありません"))
          : _isSorting
              ? _buildSortingList(filtered, categoryName) // 並び替えモード表示
              : _buildNormalList(filtered, categoryName), // 通常リスト表示
    );
  }

  /// [_buildNormalList]
  /// ─────────────────────────────────────────────────────────
  /// 通常モードでの単語一覧表示用ウィジェットを構築します。
  /// 各カードはスワイプや長押しでの各種アクション（保存、削除、他）が操作可能です。
  Widget _buildNormalList(List<Product> products, String categoryName) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return SwipeToDeleteCard(
          keyValue: ValueKey(product.name),
          // 削除確認ダイアログの表示と結果による処理
          onConfirm: () async {
            return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("削除確認"),
                    content: Text("${product.name} をリストから削除してよろしいですか？"),
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
                  ),
                ) ??
                false;
          },
          onDismissed: () async {
            // スワイプ後に削除処理を実行
            await ref
                .read(categoriesProvider.notifier)
                .updateProductAssignment(categoryName, product.name, false);
          },
          child: GestureDetector(
            onLongPress: () {
              // 長押しで各種操作メニュー（保存、チェック問題登録、並び替え、削除）のモーダルシートを表示
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: const Text("保存する"),
                          onTap: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) =>
                                  CategoryAssignmentSheet(product: product),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.check_box),
                          title: const Text("単語チェック問題に登録する"),
                          onTap: () {
                            final currentChecked =
                                ref.read(checkedQuestionsProvider);
                            if (currentChecked.contains(product.name)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("既に単語チェック問題に登録されています。"),
                                ),
                              );
                            } else {
                              ref
                                  .read(checkedQuestionsProvider.notifier)
                                  .add(product.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("単語チェック問題に登録しました。"),
                                ),
                              );
                            }
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.sort),
                          title: const Text("並び替える"),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              // 並び替えモードに移行
                              _isSorting = true;
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("削除"),
                          onTap: () async {
                            await ref
                                .read(categoriesProvider.notifier)
                                .updateProductAssignment(
                                    categoryName, product.name, false);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: ProductCard(
              product: product,
              margin: EdgeInsets.symmetric(
                vertical: context.paddingExtraSmall,
                horizontal: context.paddingExtraSmall,
              ),
              onTap: () => showProductDialog(context, product),
            ),
          ),
        );
      },
    );
  }

  /// [_buildSortingList]
  /// ─────────────────────────────────────────────────────────
  /// 並び替えモード専用のリスト表示ウィジェットを作成します。
  /// ドラッグ操作により単語の順番を更新できるようにしています。
  Widget _buildSortingList(List<Product> products, String categoryName) {
    return ReorderableListView.builder(
      itemCount: products.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        await ref.read(categoriesProvider.notifier).reorderProducts(
              categoryName,
              oldIndex,
              newIndex,
            );
      },
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          key: ValueKey(product.name),
          leading: const Icon(Icons.drag_handle),
          title: Text(
            product.name,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => showProductDialog(context, product),
        );
      },
    );
  }
}
