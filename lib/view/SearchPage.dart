import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../provider/checkedQuestionsProvider.dart';
import '../provider/productsProvider.dart';
import '../provider/searchHistoryProvider.dart';
import '../provider/searchQueryProvider.dart';
import '../utility/Product.dart';
import 'category_page/CategoryAssignmentSheet.dart';
import 'test_page/check_test/CheckedQuestionsPage.dart';
import 'SavedItemsPage.dart';
import 'category_page/CategorySelectionPage.dart';
import 'setting_page/SettingsPage.dart';
import 'WordListPage.dart';
import 'test_page/word_test/WordTestPage.dart';

/// ---------------------------------------------------------------------------
/// SearchPage
/// ---------------------------------------------------------------------------
/// 単語検索画面。ユーザーが単語名や読みから検索を行い、
/// 結果がリスト表示され、各単語の詳細ダイアログなどへ遷移できる。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

/// _SearchPageState
/// SearchPage の内部状態。検索クエリ、表示する単語のキャッシュ、
/// 並び替え処理用の状態などを管理する
class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Product>? _cachedRandomProducts;

  Future<void> _onRefresh() async {
    _cachedRandomProducts = null;
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.invalidate(productsProvider);
  }

  /// 単語詳細ダイアログを開く前に履歴に追加
  void _openProductDialog(Product product) {
    ref.read(searchHistoryProvider.notifier).addProduct(product.name);
    showProductDialog(context, product);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// _showActionSheet()
  /// 長押し時に表示するアクションシート。ここで単語の「保存」や「単語チェック問題」への登録処理を実行する
  void _showActionSheet(Product product) {
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
                  // リストへの自動割当画面等の表示
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
                  Navigator.pop(context);
                  // 既に登録されているかチェックし、なければ追加
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('単語検索'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'メニュー',
              onPressed: () {
                // メニュー表示時にもキーボードフォーカスを解除
                FocusScope.of(context).unfocus();
                // 下部モーダルシートで各種機能（保存一覧、リスト、クイズ、設定など）へ遷移
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return Container(
                      margin: EdgeInsets.all(context.paddingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(context.paddingSmall),
                            child: Text(
                              "メニュー",
                              style: TextStyle(
                                  fontSize: context.fontSizeLarge,
                                  fontWeight: FontWeight.bold),
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
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark,
                                      color: Colors.blue),
                                  context.horizontalSpaceSmall,
                                  Expanded(
                                      child: Text("保存単語",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
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
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.folder, color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("マイリスト",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
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
                                    builder: (_) => const WordTestPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.quiz, color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("単語テスト",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
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
                                        const CheckedQuestionsPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box,
                                      color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("単語チェック問題",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
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
                                        const ScheduleManagementPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                    child: Text("スケジュール管理",
                                        style: TextStyle(
                                            fontSize: context.fontSizeMedium)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          // 既存の SearchPage のモーダルメニュー内に「設定」項目を追加
// （SearchPage の build() メソッド内、メニュー表示部分の最後あたりに追加）
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: context.paddingMedium,
                                horizontal: context.paddingSmall,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.settings,
                                      color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                    child: Text(
                                      "設定",
                                      style: TextStyle(
                                          fontSize: context.fontSizeMedium),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
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
              Padding(
                padding: EdgeInsets.all(context.paddingMedium),
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
              productsAsync.when(
                loading: () => Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: context.paddingMedium),
                  child: const Center(child: CircularProgressIndicator()),
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
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: context.paddingMedium),
                      child: const Center(child: Text('一致する単語がありません')),
                    );
                  }
                  return Column(
                    children: filteredProducts.map((product) {
                      return GestureDetector(
                        onLongPress: () {
                          _showActionSheet(product);
                        },
                        onTap: () => _openProductDialog(product),
                        child: ProductCard(
                          product: product,
                          margin: EdgeInsets.symmetric(
                              vertical: context.paddingExtraSmall,
                              horizontal: context.paddingSmall),
                          onTap: () => _openProductDialog(product),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
