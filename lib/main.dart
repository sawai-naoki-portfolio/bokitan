import 'package:bookkeeping_vocabulary_notebook/providers/products_provider.dart';
import 'package:bookkeeping_vocabulary_notebook/utils/common_product_list_view.dart';
import 'package:bookkeeping_vocabulary_notebook/utils/product_card.dart';
import 'package:bookkeeping_vocabulary_notebook/utils/settings/load_quiz_filter_settings.dart';
import 'package:bookkeeping_vocabulary_notebook/utils/show_product_dialog.dart';
import 'package:bookkeeping_vocabulary_notebook/view_models/quiz_filter_settings.dart';
import 'package:bookkeeping_vocabulary_notebook/view_models/search_query_view_model.dart';
import 'package:bookkeeping_vocabulary_notebook/views/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// まず、必ず WidgetsBinding を初期化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final quizSettings = await loadQuizFilterSettings();

  runApp(
    ProviderScope(
      overrides: [
        quizFilterSettingsProvider.overrideWith((ref) => quizSettings),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '単語検索＆保存アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Murecho',
        useMaterial3: false,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SearchPage(),
    );
  }
}

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
          // 検索クエリが空ならランダム表示、入力があればフィルター表示
          final filteredProducts = (searchQuery.isNotEmpty)
              ? products
                  .where((p) =>
                      p.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      p.yomigana
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                  .toList()
              : products; // 例として全件表示

          return CommonProductListView(
            products: filteredProducts,
            itemBuilder: (context, product) {
              return GestureDetector(
                onLongPress: () => showProductDialog(context, product),
                child: ProductCard(
                  product: product,
                  onTap: () => showProductDialog(context, product),
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
