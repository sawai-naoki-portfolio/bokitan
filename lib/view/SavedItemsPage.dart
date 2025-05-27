import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/CommonProductListView.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/checkedQuestionsProvider.dart';
import '../provider/productsProvider.dart';
import '../provider/savedItemsProvider.dart';
import '../utility/SwipeToDeleteCard.dart';
import 'category_page/CategoryAssignmentSheet.dart';

//////////////////////////////////////////////
// SavedItemsPage
//////////////////////////////////////////////
// 保存した単語（お気に入りなど）を一覧表示する画面です。
// 各商品（ProductCard）のタップ・スワイプ、長押しアクションから詳細ダイアログや
// カテゴリー割当、単語チェック問題登録などの操作を実行できます。
class SavedItemsPage extends ConsumerWidget {
  const SavedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // savedItemsProvider から保存済みの単語名リスト、そして productsProvider で全単語情報を取得
    final savedItems = ref.watch(savedItemsProvider);
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (allProducts) {
          // 保存済みの商品名リストから Product オブジェクトを抽出
          final savedProducts = savedItems
              .where((name) => allProducts.any((p) => p.name == name))
              .map((name) => allProducts.firstWhere((p) => p.name == name))
              .toList();

          return CommonProductListView(
            products: savedProducts,
            itemBuilder: (context, product) {
              return SwipeToDeleteCard(
                keyValue: ValueKey(product.name),
                onConfirm: () async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("削除確認"),
                          content: Text("${product.name} を削除してよろしいですか？"),
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
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(product.name);
                },
                child: GestureDetector(
                  onLongPress: () {
                    // 長押し時はカテゴリー割当ウィジェット表示などを実行
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.bookmark),
                              title: const Text("保存する"),
                              onTap: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
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
                          ],
                        ),
                      ),
                    );
                  },
                  child: ProductCard(
                    product: product,
                    onTap: () => showProductDialog(context, product),
                    margin: EdgeInsets.symmetric(
                      vertical: context.paddingExtraSmall,
                      horizontal: context.paddingExtraSmall,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////
// SavedItemsPageState
//////////////////////////////////////////////
// SavedItemsPage の内部状態を管理し、保存単語の並び替えモードを提供します。
// ユーザーはアイコンをタップして並び替えモードに切り替え、
// ドラッグ＆ドロップにより保存順を変更できます。
class SavedItemsPageState extends ConsumerState<SavedItemsPage> {
  bool _isSorting = false; // 並び替えモードか否か

  @override
  Widget build(BuildContext context) {
    final savedItems = ref.watch(savedItemsProvider);
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSorting ? const Icon(Icons.check) : const Icon(null),
            onPressed: () {
              setState(() {
                _isSorting = !_isSorting;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
          data: (products) {
            final savedProducts = savedItems
                .where((itemName) => products.any((p) => p.name == itemName))
                .map((itemName) =>
                    products.firstWhere((p) => p.name == itemName))
                .toList();
            if (savedProducts.isEmpty) {
              return const Center(child: Text('保存された単語はありません'));
            }
            if (_isSorting) {
              return ReorderableListView.builder(
                itemCount: savedProducts.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  List<String> newOrder = List.from(savedItems);
                  final item = newOrder.removeAt(oldIndex);
                  newOrder.insert(newIndex, item);
                  await ref
                      .read(savedItemsProvider.notifier)
                      .reorderItems(newOrder);
                },
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  return ListTile(
                    key: ValueKey(product.name),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    onTap: () => showProductDialog(context, product),
                  );
                },
              );
            } else {
              return ListView.builder(
                itemCount: savedProducts.length,
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  return Dismissible(
                    key: ValueKey(product.name),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.paddingMedium),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("削除確認"),
                            content: Text("${product.name} を削除してよろしいですか？"),
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
                      return result ?? false;
                    },
                    onDismissed: (direction) async {
                      await ref
                          .read(savedItemsProvider.notifier)
                          .removeItem(product.name);
                    },
                    child: GestureDetector(
                      onLongPress: () {
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
                                        builder: (context) =>
                                            CategoryAssignmentSheet(
                                                product: product),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.check_box),
                                    title: const Text("単語チェック問題に登録する"),
                                    onTap: () {
                                      final currentChecked =
                                          ref.read(checkedQuestionsProvider);
                                      if (currentChecked
                                          .contains(product.name)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text("既に単語チェック問題に登録されています。")),
                                        );
                                      } else {
                                        ref
                                            .read(checkedQuestionsProvider
                                                .notifier)
                                            .add(product.name);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text("単語チェック問題に登録しました。")),
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
                                          .read(savedItemsProvider.notifier)
                                          .removeItem(product.name);
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
                        onTap: () => showProductDialog(context, product),
                        margin: EdgeInsets.symmetric(
                            vertical: context.paddingMedium),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
