import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/CommonProductListView.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/productsProvider.dart';
import '../../provider/searchHistoryProvider.dart';
import '../../utility/Product.dart';

class SearchHistoryPage extends ConsumerWidget {
  const SearchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // プロバイダーから履歴リストを取得（先頭が最新）
    final history = ref.watch(searchHistoryProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("検索履歴"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              ref.read(searchHistoryProvider.notifier).clearHistory();
            },
          )
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
        data: (allProducts) {
          // history の各単語名に対して、全単語リストから存在する場合のみ追加する
          final historyProducts = <Product>[];
          for (final name in history) {
            // 全単語リスト内で name と一致する商品が存在するかチェック
            final matchingProducts =
                allProducts.where((p) => p.name == name).toList();
            if (matchingProducts.isNotEmpty) {
              historyProducts.add(matchingProducts.first);
            }
          }
          // 最新順に追加しているので、historyProducts の先頭が最新
          // 15 件以上ある場合は先頭 15 件のみを保持
          final limitedHistoryProducts = historyProducts.take(15).toList();

          if (limitedHistoryProducts.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
              child: Center(
                child: Text(
                  "検索履歴がありません",
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
              ),
            );
          }
          return CommonProductListView(
            products: limitedHistoryProducts,
            itemBuilder: (context, product) {
              return GestureDetector(
                onTap: () => showProductDialog(context, product),
                child: ProductCard(
                  product: product,
                  margin: EdgeInsets.symmetric(
                    vertical: context.paddingExtraSmall,
                    horizontal: context.paddingExtraSmall,
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
