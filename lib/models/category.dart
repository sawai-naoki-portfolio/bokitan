/// カテゴリモデル：ユーザーが登録する各カテゴリ
class Category {
  final String name;
  final List<String> products;

  Category({required this.name, List<String>? products})
      : products = products ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'products': products,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      products: List<String>.from(json['products'] as List),
    );
  }
}
