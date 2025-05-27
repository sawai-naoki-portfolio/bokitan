import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:flutter/material.dart';

import '../../utility/Product.dart';

/// ---------------------------------------------------------------------------
/// ProductCard
/// ─ 各単語の情報（名前、説明など）を表示するカードウィジェット
/// ---------------------------------------------------------------------------
class ProductCard extends StatelessWidget {
  final Product product;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets margin;

  const ProductCard({
    super.key,
    required this.product,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.all(10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // 左側に円形アバター（先頭文字を表示）
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade300,
          child: Text(
            product.name.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: context.fontSizeMedium),
        ),
        subtitle: Text(
          product.description,
          style: TextStyle(fontSize: context.fontSizeSmall),
        ),
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
