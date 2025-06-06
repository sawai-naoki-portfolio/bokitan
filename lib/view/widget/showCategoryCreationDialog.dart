
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// showCategoryCreationDialog
/// ─ 新規リストを作成するためのシンプルな入力ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<String?> showCategoryCreationDialog(BuildContext context) async {
  String temp = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("新規リストの作成"),
        content: TextField(
          onChanged: (value) => temp = value,
          decoration: const InputDecoration(hintText: "リスト名"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, temp),
            child: const Text("作成"),
          ),
        ],
      );
    },
  );
}
