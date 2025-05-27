import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// showCategoryDeleteDialog
/// ─ カテゴリー削除前の確認ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<bool?> showCategoryDeleteDialog(
    BuildContext context, String categoryName) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("カテゴリーの削除"),
      content: Text("カテゴリー「$categoryName」を削除してよろしいですか？"),
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
