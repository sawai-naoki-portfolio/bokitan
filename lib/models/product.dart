/// --- モデル・プロバイダー系 ---
class Product {
  final String name;
  final String yomigana;
  final String description;
  final String category; // 追加

  Product({
    required this.name,
    required this.yomigana,
    required this.description,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      yomigana: json['yomigana'] ?? "",
      description: json['description'],
      category: json['category'] ?? '未分類', // デフォルト値などを設定可能
    );
  }
}
