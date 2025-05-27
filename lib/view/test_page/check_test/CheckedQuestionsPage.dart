import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/ProductCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/checkedQuestionsProvider.dart';
import '../../../provider/productsProvider.dart';
import '../../../utility/Product.dart';
import '../../../utility/SwipeToDeleteCard.dart';
import '../../category_page/CategoryAssignmentSheet.dart';
import 'CheckboxTestPage.dart';

/// ---------------------------------------------------------------------------
/// CheckedQuestionsPage
/// ---------------------------------------------------------------------------
/// ユーザーが「単語チェック問題」として登録した単語の一覧を表示する画面です。
/// ・リスト上では各単語に対して、タップで詳細ダイアログやスワイプで削除操作が可能です。
/// ・画面上部には、「問題出題」ボタンがあり、チェックされた単語だけを対象にクイズを開始します。
class CheckedQuestionsPage extends ConsumerStatefulWidget {
  const CheckedQuestionsPage({super.key});

  @override
  CheckedQuestionsPageState createState() => CheckedQuestionsPageState();
}

/// ---------------------------------------------------------------------------
/// CheckedQuestionsPageState
/// ---------------------------------------------------------------------------
/// CheckedQuestionsPage の内部状態を管理するクラスです。
/// ・プロバイダーから取得したチェック済み単語に基づき、
///   リストを表示、削除、並び替え（必要に応じて）の機能を提供します。
class CheckedQuestionsPageState extends ConsumerState<CheckedQuestionsPage> {
  // 並び替えモードフラグ（今回は固定モードで false）
  final bool _isSorting = false;
  List<Product>? _sortedProducts;

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
          // 画面上部に「問題出題」ボタンを配置（チェック済み単語がある場合のみアクティブ）
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: checked.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckboxTestPage(),
                        ),
                      );
                    }
                  : null,
              child: Text("問題出題",
                  style: TextStyle(fontSize: context.fontSizeExtraLarge)),
            ),
          ),
          // チェック済み単語リストの表示部
          Padding(
            padding: EdgeInsets.only(top: context.paddingExtraLarge * 2.5),
            child: Padding(
              padding: EdgeInsets.all(context.paddingExtraSmall),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
                data: (products) {
                  final filtered =
                      products.where((p) => checked.contains(p.name)).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text("チェックされた問題はありません"));
                  }
                  if (_isSorting) {
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
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return SwipeToDeleteCard(
                          keyValue: ValueKey(product.name),
                          // スワイプで単語を削除する際に確認ダイアログを表示する
                          onConfirm: () async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("削除確認"),
                                    content:
                                        Text("${product.name} を削除してよろしいですか？"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("キャンセル"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("削除"),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: () async {
                            await ref
                                .read(checkedQuestionsProvider.notifier)
                                .remove(product.name);
                          },
                          child: GestureDetector(
                            onLongPress: () {
                              _showActionSheet(product);
                            },
                            child: ProductCard(
                              product: product,
                              onTap: () => showProductDialog(context, product),
                              margin: EdgeInsets.symmetric(
                                  vertical: context.paddingExtraSmall),
                            ),
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

  /// _showActionSheet()
  /// 下部モーダルシートで、保存や削除などの操作項目を表示する
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
                  if (!context.mounted) return;
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
