import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../utils/product_card.dart';
import '../../utils/show_product_dialog.dart';
import '../../view_models/categories_view_model.dart';
import '../../providers/checked_questions_provider.dart';
import '../../view_models/products_view_model.dart';
import '../../utils/category_assignment_sheet.dart';

class CategoryItemsPage extends ConsumerStatefulWidget {
  final Category category;

  const CategoryItemsPage({super.key, required this.category});

  @override
  CategoryItemsPageState createState() => CategoryItemsPageState();
}

class CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  bool _isSorting = false; // 並び替えモードを管理するフラグ

  @override
  Widget build(BuildContext context) {
    // 現在のカテゴリ情報を取得（最新のもので上書き）
    final allCategories = ref.watch(categoriesProvider);
    final currentCategory = allCategories.firstWhere(
      (cat) => cat.name == widget.category.name,
      orElse: () => widget.category,
    );
    // assets側のプロダクトやユーザー追加分などを統合した全商品一覧
    final allProducts = ref.watch(allProductsProvider);
    // カテゴリーに登録済みの商品一覧（順番は currentCategory.products の順）
    final filtered = currentCategory.products.map((productName) {
      return allProducts.firstWhere((p) => p.name == productName);
    }).toList();

    // カテゴリー名は後々各処理に利用するため変数に格納
    final categoryName = currentCategory.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("カテゴリー: $categoryName"),
        centerTitle: true,
        actions: [
          // 並び替えモード中はチェックアイコンを表示し、そのタップで通常モードに戻す
          if (_isSorting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  _isSorting = false;
                });
              },
            )
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("このカテゴリーに商品はありません"))
          : _isSorting
              ? _buildSortingList(filtered, categoryName)
              : _buildNormalList(filtered, categoryName),
    );
  }

  /// 通常モード：WordListPage と同じ単語リスト表示
  Widget _buildNormalList(List<Product> products, String categoryName) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          onTap: () => showProductDialog(context, product),
          onLongPress: () {
            // 長押しで下部シートを表示
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
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 並び替えモード：ドラッグで並び替え可能なリスト表示
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
          title: Text(product.name),
          subtitle: Text(product.description),
          onTap: () => showProductDialog(context, product),
        );
      },
    );
  }
}
