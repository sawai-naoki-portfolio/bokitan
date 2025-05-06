import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/products_provider.dart';
import '../../utils/common_product_list_view.dart';
import '../../utils/product_card.dart';
import '../../utils/show_product_dialog.dart';
import '../../providers/checked_questions_provider.dart';
import '../../view_models/saved_items_view_model.dart';
import '../../utils/category_assignment_sheet.dart';

class SavedItemsPage extends ConsumerWidget {
  const SavedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // 保存済みリストに沿って表示するProductを取得
          final savedProducts = savedItems
              .where((name) => allProducts.any((p) => p.name == name))
              .map((name) => allProducts.firstWhere((p) => p.name == name))
              .toList();

          return CommonProductListView(
            products: savedProducts,
            itemBuilder: (context, product) {
              return Dismissible(
                key: ValueKey(product.name),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
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
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(product.name);
                },
                child: GestureDetector(
                  onLongPress: () {
                    // 長押し時の下部シート表示の例
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
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("既に単語チェック問題に登録されています。"),
                                  ));
                                } else {
                                  ref
                                      .read(checkedQuestionsProvider.notifier)
                                      .add(product.name);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("単語チェック問題に登録しました。"),
                                  ));
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
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                ),
              );
            },
            // onRefreshも必要なら設定
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
              ref.invalidate(productsProvider);
            },
          );
        },
      ),
    );
  }
}

class SavedItemsPageState extends ConsumerState<SavedItemsPage> {
  // 並び替えモードのフラグ（初期状態は通常モード）
  bool _isSorting = false;

  @override
  Widget build(BuildContext context) {
    final savedItems = ref.watch(savedItemsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
        actions: [
          // 並び替えモード中は「完了（チェックアイコン）」、通常モードでは「並び替え（ソートアイコン）」を表示
          IconButton(
            icon: _isSorting ? const Icon(Icons.check) : const Icon(null),
            onPressed: () {
              // アイコン押下で並び替えモードのオン／オフを切り替え
              setState(() {
                _isSorting = !_isSorting;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
          data: (products) {
            // 保存済みリストに沿って対象 Product を抽出
            final savedProducts = savedItems
                .where((itemName) => products.any((p) => p.name == itemName))
                .map((itemName) =>
                    products.firstWhere((p) => p.name == itemName))
                .toList();

            if (savedProducts.isEmpty) {
              return const Center(child: Text('保存された単語はありません'));
            }

            if (_isSorting) {
              // ※ 並び替えモード：ReorderableListView を利用
              return ReorderableListView.builder(
                itemCount: savedProducts.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  // 並び替え後のリスト順を savedItemsProvider に反映
                  List<String> newOrder = List.from(savedItems);
                  final item = newOrder.removeAt(oldIndex);
                  newOrder.insert(newIndex, item);
                  await ref
                      .read(savedItemsProvider.notifier)
                      .reorderItems(newOrder);
                },
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  // 並び替えモードでは、カード全体は ListTile（もしくは ProductCard の見た目に近いもの）にして、
                  // 右側のアイコンをドラッグハンドル（二点アイコン）に変更
                  return ListTile(
                    key: ValueKey(product.name),
                    // ドラッグ可能なアイコン
                    leading: const Icon(Icons.drag_handle),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    // タップ時は商品詳細ダイアログを表示。※UIの他の部分はそのまま
                    onTap: () => showProductDialog(context, product),
                  );
                },
              );
            } else {
              // ※ 通常モード：元の ListView.builder を利用し、長押しで下部シート表示
              return ListView.builder(
                itemCount: savedProducts.length,
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  return Dismissible(
                    key: ValueKey(product.name),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      final result = await showDialog<bool>(
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
                      return result ?? false;
                    },
                    onDismissed: (direction) async {
                      await ref
                          .read(savedItemsProvider.notifier)
                          .removeItem(product.name);
                    },
                    child: GestureDetector(
                      onLongPress: () {
                        // 長押し時に下部シートで各アクションを表示
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
                                      // 保存するでカテゴリー割当シートを表示
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
                                      // チェック問題に既に登録済みか確認
                                      final currentChecked =
                                          ref.read(checkedQuestionsProvider);
                                      if (currentChecked
                                          .contains(product.name)) {
                                        // 既に存在している場合は状態を変更せずに通知する
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("既に単語チェック問題に登録されています。"),
                                          ),
                                        );
                                      } else {
                                        // 未登録の場合のみ追加
                                        ref
                                            .read(checkedQuestionsProvider
                                                .notifier)
                                            .add(product.name);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                      // 並び替えモードに切り替え
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
                        margin: const EdgeInsets.symmetric(vertical: 8),
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
