import 'package:flutter/material.dart';

import '../models/product.dart';
import 'memo.dart';

void showProductDialog(BuildContext context, Product product) {
  showDialog(
    context: context,
    builder: (context) {
      // StatefulBuilder で AlertDialog 全体の再描画を必要最小限に抑える
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            // タイトル部分：左側に商品名、右側にチェックボックス（チェックボックス部分は Consumer で独立）
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            // content 部分：最大高さを設定して SingleChildScrollView でスクロール可能に
            content: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品説明
                    Text(product.description),
                    const SizedBox(height: 10),
                    // 毎回最新の memo を反映する MemoDisplay を利用
                    MemoDisplay(product: product),
                  ],
                ),
              ),
            ),
            actions: [
              // 「メモを書く」ボタン：メモ入力後に setState で AlertDialog を再描画
              TextButton(
                onPressed: () async {
                  await showMemoDialog(context, product);
                  setState(() {}); // 保存後に再描画して最新のメモを反映
                },
                child: const Text("メモを書く"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("閉じる"),
              ),
            ],
          );
        },
      );
    },
  );
}
