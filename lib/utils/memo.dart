// ユーザーが自由にメモ入力できるダイアログ
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

// メモ表示ウィジェット（キャッシュせずに毎回 loadMemo を呼び出す）
class MemoDisplay extends StatelessWidget {
  final Product product;

  const MemoDisplay({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox で最低50pxの高さを確保
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: FutureBuilder<String>(
        future: loadMemo(product),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if (snapshot.hasError) return const SizedBox();
          final memo = snapshot.data ?? "";
          if (memo.isNotEmpty) {
            return Text(
              "メモ: $memo",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

Future<void> showMemoDialog(BuildContext context, Product product) async {
  final prefs = await SharedPreferences.getInstance();
  final String initialMemo = prefs.getString('memo_${product.name}') ?? "";
  final TextEditingController controller =
      TextEditingController(text: initialMemo);

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("メモを書く"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "ここにメモを入力してください",
          ),
          maxLines: null, // 複数行入力可能
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              final memo = controller.text.trim();
              await prefs.setString('memo_${product.name}', memo);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("メモが保存されました")),
              );
            },
            child: const Text("保存"),
          ),
        ],
      );
    },
  );
}

Future<String> loadMemo(Product product) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('memo_${product.name}') ?? "";
}
