import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// showCategoryDeleteDialog
/// ─ リスト削除前の確認ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<bool?> showCategoryDeleteDialog(
    BuildContext context, String categoryName) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("リストの削除"),
      content: Text("リスト「$categoryName」を削除してよろしいですか？"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("削除"),
        ),
      ],
    ),
  );
}
