import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/CommonProductListView.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/productsProvider.dart';
import '../provider/searchQueryProvider.dart';

///////////////////////////////////////////////////////////////
// WordSearchPage
///////////////////////////////////////////////////////////////
/// [WordSearchPage] は、ユーザーが単語名や読みで Product を検索できる画面です。
/// ・検索テキストフィールドに入力されたクエリにより、対象の Product をフィルターして表示します。
/// ・入力がない場合は、ランダムに選ばれた数件の単語をキャッシュして表示する仕組みになっています。
class WordSearchPage extends ConsumerWidget {
  const WordSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語検索'),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (products) {
          final filteredProducts = (searchQuery.isNotEmpty)
              ? products.where((p) {
                  final query = searchQuery.toLowerCase();
                  return p.name.toLowerCase().contains(query) ||
                      p.yomigana.toLowerCase().contains(query);
                }).toList()
              : products;

          return CommonProductListView(
            products: filteredProducts,
            itemBuilder: (context, product) {
              return GestureDetector(
                onLongPress: () => showProductDialog(context, product),
                child: ProductCard(
                  product: product,
                  onTap: () => showProductDialog(context, product),
                  margin: EdgeInsets.symmetric(
                      vertical: context.paddingMedium,
                      horizontal: context.paddingMedium),
                ),
              );
            },
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
