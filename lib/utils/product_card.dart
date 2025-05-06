import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // 追加
  final EdgeInsets margin;

  const ProductCard({
    super.key,
    required this.product,
    this.trailing,
    this.onTap,
    this.onLongPress, // 追加
    this.margin = const EdgeInsets.all(10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade300,
          child: Text(
            product.name.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          product.description,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress, // 追加
      ),
    );
  }
}
