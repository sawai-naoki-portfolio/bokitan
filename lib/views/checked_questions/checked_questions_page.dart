import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../utils/product_card.dart';
import '../../utils/show_product_dialog.dart';
import '../../providers/checked_questions_provider.dart';
import '../../utils/category_assignment_sheet.dart';
import 'check_test_page.dart';

class CheckedQuestionsPage extends ConsumerStatefulWidget {
  const CheckedQuestionsPage({super.key});

  @override
  CheckedQuestionsPageState createState() => CheckedQuestionsPageState();
}

class CheckedQuestionsPageState extends ConsumerState<CheckedQuestionsPage> {
  final bool _isSorting = false;
  List<Product>? _sortedProducts; // 並び替え用の一時リスト

  @override
  Widget build(BuildContext context) {
    final checked = ref.watch(checkedQuestionsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("単語チェック問題"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 画面上部に固定の「問題出題」ボタンを表示
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckTestPage()),
                );
              },
              child: const Text("問題出題", style: TextStyle(fontSize: 18)),
            ),
          ),
          // 下部のリスト表示部分。上部ボタン分の空間を確保するために Padding を使用
          Padding(
            padding: const EdgeInsets.only(top: 80.0),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
                data: (products) {
                  // チェックされている商品のみフィルターする
                  final filtered =
                      products.where((p) => checked.contains(p.name)).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text("チェックされた問題はありません"));
                  }
                  if (_isSorting) {
                    // 並び替えモードの場合
                    _sortedProducts ??= List<Product>.from(filtered);
                    return ReorderableListView.builder(
                      itemCount: _sortedProducts!.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _sortedProducts!.removeAt(oldIndex);
                          _sortedProducts!.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final product = _sortedProducts![index];
                        return ListTile(
                          key: ValueKey(product.name),
                          title: Text(product.name),
                          subtitle: Text(product.description),
                          onTap: () => showProductDialog(context, product),
                        );
                      },
                    );
                  } else {
                    // 通常モード
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return GestureDetector(
                          onLongPress: () {
                            _showActionSheet(product);
                          },
                          child: ProductCard(
                            product: product,
                            onTap: () => showProductDialog(context, product),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 長押し時に表示するボトムシート
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
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        CategoryAssignmentSheet(product: product),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("削除"),
                onTap: () async {
                  await ref
                      .read(checkedQuestionsProvider.notifier)
                      .remove(product.name);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
