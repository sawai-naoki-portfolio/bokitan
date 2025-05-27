
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/Product.dart';

/// ---------------------------------------------------------------------------
/// showMemoDialog
/// ─ Productに対してユーザーがメモを書き込む入力ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<void> showMemoDialog(BuildContext context, Product product) async {
  final prefs = await SharedPreferences.getInstance();
  final String initialMemo = prefs.getString('memo_${product.name}') ?? "";
  final controller = TextEditingController(text: initialMemo);
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("メモを書く"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "ここにメモを入力してください"),
          maxLines: null,
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
              if (!context.mounted) return;
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
