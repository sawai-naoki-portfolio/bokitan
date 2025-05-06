import 'package:flutter/material.dart';

import '../models/product.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("新規商品追加"),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: "商品名"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              // 商品名のみでProductインスタンスを生成（読み仮名、説明は空文字）
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
