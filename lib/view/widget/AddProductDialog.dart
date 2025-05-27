
// ============================================================================
// AddProductDialog Widget
// -----------------------------------------------------------------------------
// このウィジェットは「新規単語追加」ダイアログを表示します。
// ユーザーはテキストフィールドに単語（Product）の名前を入力し、
// 「追加」ボタンを押すことで新たな単語を作成できます。
// 「キャンセル」ボタンを押すとダイアログを閉じます。
// ============================================================================
import 'package:flutter/material.dart';

import '../../utility/Product.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

// ============================================================================
// AddProductDialogState
// -----------------------------------------------------------------------------
// この状態クラスは、AddProductDialog の内部状態を管理します。
// ・TextEditingController を用いてユーザーの入力を保持
// ・「追加」ボタンタップ時に、入力が空でなければ新しい Product インスタンスを作成し、
//   ダイアログを閉じる際にその新規商品を返します。
// ・リソース解放のため、dispose() メソッドでコントローラーを破棄します。
// ============================================================================
class AddProductDialogState extends State<AddProductDialog> {
  // ユーザーが新規単語（Productの名前）を入力するためのテキストコントローラー
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    // 使用済みのコントローラーを破棄してリソースを解放
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("新規単語追加"),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: "単語"),
      ),
      actions: [
        // キャンセルボタン：ユーザーの入力内容を破棄してダイアログを閉じる
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        // 追加ボタン：入力された単語が空でなければ新たな Product を作成し、
// ダイアログ終了時にその商品を返す
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final newProduct = Product(
                name: name,
                yomigana: "",
                description: "",
                category: '',
              );
              Navigator.pop(context, newProduct);
            }
          },
          child: const Text("追加"),
        ),
      ],
    );
  }
}
