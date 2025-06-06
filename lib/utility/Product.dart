/// ---------------------------------------------------------------------------
/// Product クラス
/// ─ 単語（もしくは単語）のデータモデル。各単語は名前、読み仮名、説明、リストを保持します。
/// ---------------------------------------------------------------------------
class Product {
  final String name;
  final String yomigana;
  final String description;
  final String category;

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
      category: json['category'] ?? '未分類',
    );
  }
}
