import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showProductDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/productsProvider.dart';
import '../../utility/Product.dart';
import '../../utility/loadMemo.dart';

class MemoListPage extends ConsumerStatefulWidget {
  const MemoListPage({super.key});

  @override
  ConsumerState<MemoListPage> createState() => _MemoListPageState();
}

class _MemoListPageState extends ConsumerState<MemoListPage> {
  /// 全単語リストから、各商品のメモを loadMemo() で取得し、
  /// メモが記載されている商品のみ抽出する
  Future<List<Product>> _getMemoProducts(List<Product> products) async {
    List<Product> memoProducts = [];
    for (var product in products) {
      final memo = await loadMemo(product);
      if (memo.trim().isNotEmpty) {
        memoProducts.add(product);
      }
    }
    return memoProducts;
  }

  /// 指定された商品のメモをクリアする（SharedPreferencesから削除）
  Future<void> _clearMemo(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('memo_${product.name}');
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("メモ一覧"),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
        data: (products) {
          return FutureBuilder<List<Product>>(
            future: _getMemoProducts(products),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final memoProducts = snapshot.data ?? [];
              if (memoProducts.isEmpty) {
                return Center(
                  child: Text("保存されているメモはありません",
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                );
              }
              return ListView.builder(
                itemCount: memoProducts.length,
                itemBuilder: (context, index) {
                  final product = memoProducts[index];
                  return Dismissible(
                    key: ValueKey(product.name),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: context.paddingMedium),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("削除の確認"),
                                content:
                                    Text("${product.name} のメモを削除してよろしいですか？"),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("キャンセル")),
                                  ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("削除")),
                                ],
                              );
                            },
                          ) ??
                          false;
                    },
                    onDismissed: (direction) async {
                      await _clearMemo(product);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("メモが削除されました")),
                      );
                      setState(() {}); // 再評価して削除反映
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: context.paddingExtraSmall,
                        horizontal: context.paddingSmall,
                      ),
                      title: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: loadMemo(product),
                        builder: (context, memoSnapshot) {
                          if (memoSnapshot.connectionState !=
                              ConnectionState.done) {
                            return const Text("読み込み中...");
                          }
                          String memoText = memoSnapshot.data ?? "";
                          if (memoText.length > 15) {
                            memoText = "${memoText.substring(0, 15)}...";
                          }
                          return Text(
                            memoText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.fontSizeSmall,
                                color: Colors.grey[600]),
                          );
                        },
                      ),
                      onLongPress: () async {
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("メモ削除の確認"),
                              content: Text("${product.name} のメモを削除してよろしいですか？"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("キャンセル")),
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("削除")),
                              ],
                            );
                          },
                        );
                        if (confirm ?? false) {
                          await _clearMemo(product);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("メモが削除されました")),
                          );
                          setState(() {}); // 再描画
                        }
                      },
                      onTap: () => showProductDialog(context, product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
