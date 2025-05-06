import 'package:bookkeeping_vocabulary_notebook/views/saved_items/saved_items_page.dart';
import 'package:bookkeeping_vocabulary_notebook/views/settings.dart';
import 'package:bookkeeping_vocabulary_notebook/views/word_list/word_list_page.dart';
import 'package:bookkeeping_vocabulary_notebook/views/word_test/word_test_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../utils/product_card.dart';
import '../utils/show_product_dialog.dart';
import '../providers/checked_questions_provider.dart';
import '../view_models/search_query_view_model.dart';
import '../utils/category_assignment_sheet.dart';
import 'category_items/category_selection_page.dart';
import 'checked_questions/checked_questions_page.dart';
import 'journal_entry_quiz/journal_entry_quiz_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // 検索クエリが空の場合に利用するランダムな商品リストのキャッシュ
  List<Product>? _cachedRandomProducts;

  // 並び替えモード用の状態変数
  final bool _isSorting = false;
  List<Product>? _sortedProducts;

  Future<void> _onRefresh() async {
    _cachedRandomProducts = null; // キャッシュクリア
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.invalidate(productsProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 長押し時に表示するアクションシート
  void _showActionSheet(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // 「保存する」：カテゴリー割当ウィジェットを表示
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
              // 「チェック問題に登録する」：既に登録済みなら通知、未登録なら追加
              ListTile(
                leading: const Icon(Icons.check_box),
                title: const Text("単語チェック問題に登録する"),
                onTap: () {
                  Navigator.pop(context);
                  final currentChecked = ref.read(checkedQuestionsProvider);
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
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語検索'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'メニュー',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "メニュー",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WordTestPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.quiz, color: Colors.blue),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Text("単語テスト",
                                        style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CheckedQuestionsPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.check_box, color: Colors.blue),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Text("単語チェック問題",
                                        style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // 既存項目
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SavedItemsPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.bookmark, color: Colors.blue),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Text("保存単語",
                                        style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CategorySelectionPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.folder, color: Colors.blue),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Text("カテゴリーリスト",
                                        style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),
                        // InkWell(
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //           builder: (_) => const JournalEntryQuizPage()),
                        //     );
                        //   },
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(
                        //         vertical: 16, horizontal: 16),
                        //     child: const Row(
                        //       children: [
                        //         Icon(Icons.sort, color: Colors.blue),
                        //         SizedBox(width: 16),
                        //         Expanded(
                        //             child: Text("仕訳問題",
                        //                 style: TextStyle(fontSize: 16))),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const Divider(height: 1),
                        // // ★ 新規追加：設定項目
                        // // 例：SearchPageのメニュー表示部分（既存項目の後ろに追加）
                        // InkWell(
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //           builder: (_) => const SettingsPage()),
                        //     );
                        //   },
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(
                        //         vertical: 16, horizontal: 16),
                        //     child: const Row(
                        //       children: [
                        //         Icon(Icons.settings, color: Colors.blue),
                        //         SizedBox(width: 16),
                        //         Expanded(
                        //           child: Text("設定",
                        //               style: TextStyle(fontSize: 16)),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),

                        const Divider(height: 1),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WordListPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.list, color: Colors.blue),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Text("単語一覧",
                                        style: TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // 検索入力フィールド
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '単語名を入力',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _cachedRandomProducts = null;
                  }
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
            // 単語リスト部分
            productsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
              data: (products) {
                List<Product> filteredProducts;
                if (searchQuery.isNotEmpty) {
                  filteredProducts = products.where((p) {
                    final query = searchQuery.toLowerCase();
                    return p.name.toLowerCase().contains(query) ||
                        p.yomigana.toLowerCase().contains(query);
                  }).toList();
                } else {
                  _cachedRandomProducts ??= () {
                    final randomizedProducts = List<Product>.from(products);
                    randomizedProducts.shuffle();
                    return randomizedProducts.take(15).toList();
                  }();
                  filteredProducts = _cachedRandomProducts!;
                }

                if (filteredProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('一致する単語がありません')),
                  );
                }

                if (_isSorting) {
                  // 並び替えモード：初回は現在のフィルタ結果から一時リストを生成
                  _sortedProducts ??= List<Product>.from(filteredProducts);
                  return SizedBox(
                    height: filteredProducts.length * 80, // 適宜リスト高さを調整
                    child: ReorderableListView.builder(
                      itemCount: _sortedProducts!.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final product = _sortedProducts!.removeAt(oldIndex);
                          _sortedProducts!.insert(newIndex, product);
                        });
                      },
                      itemBuilder: (context, index) {
                        final product = _sortedProducts![index];
                        return GestureDetector(
                          key: ValueKey(product.name),
                          onLongPress: () {
                            _showActionSheet(product);
                          },
                          child: ProductCard(
                            product: product,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            onTap: () => showProductDialog(context, product),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  // 通常モード：各項目をGestureDetectorでラップして長押しアクションを実装
                  return Column(
                    children: filteredProducts.map((product) {
                      return GestureDetector(
                        onLongPress: () {
                          _showActionSheet(product);
                        },
                        child: ProductCard(
                          product: product,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          onTap: () => showProductDialog(context, product),
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
