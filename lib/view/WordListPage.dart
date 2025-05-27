import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/CommonProductListView.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/checkedQuestionsProvider.dart';
import '../provider/productsProvider.dart';
import '../utility/Product.dart';
import 'CategoryAssignmentSheet.dart';

class WordListPage extends ConsumerStatefulWidget {
  const WordListPage({super.key});

  @override
  WordListPageState createState() => WordListPageState();
}

class WordListPageState extends ConsumerState<WordListPage> {
  // 初期のカテゴリは「全て」
  String selectedCategory = '全て';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("単語一覧"),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (products) {
          // すべてのカテゴリ情報を抽出
          final Set<String> categorySet =
              products.map((p) => p.category).toSet();
          final List<String> categories = ['全て', ...categorySet];

          // 選択されたカテゴリによって商品のリストをフィルタリング
          final List<Product> filteredProducts = selectedCategory == '全て'
              ? products
              : products.where((p) => p.category == selectedCategory).toList();

          return Column(
            children: [
              // フィルター用のドロップダウンを上部に配置
              Padding(
                padding: EdgeInsets.all(context.paddingMedium),
                child: Row(
                  children: [
                    Text(
                      "カテゴリ絞り込み:",
                      style: TextStyle(fontSize: context.fontSizeMedium),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              selectedCategory = newVal;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 商品リストの表示部分を共通ウィジェットで管理
              Expanded(
                child: CommonProductListView(
                  products: filteredProducts,
                  itemBuilder: (context, product) {
                    return GestureDetector(
                      onLongPress: () {
                        // 長押し時に詳細ボトムシートなど表示
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
                                            .showSnackBar(const SnackBar(
                                          content: Text("既に単語チェック問題に登録されています。"),
                                        ));
                                      } else {
                                        ref
                                            .read(checkedQuestionsProvider
                                                .notifier)
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
                            );
                          },
                        );
                      },
                      child: ProductCard(
                        product: product,
                        onTap: () => showProductDialog(context, product),
                        margin: EdgeInsets.symmetric(
                            vertical: context.paddingExtraSmall,
                            horizontal: context.paddingExtraSmall),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
