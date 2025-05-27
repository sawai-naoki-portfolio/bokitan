import 'Product.dart';

/// ---------------------------------------------------------------------------
/// WordTestQuestion
/// ─ 単語テストの各問題を管理するデータクラス
/// ---------------------------------------------------------------------------
class WordTestQuestion {
  final Product product;
  final List<String> options;
  String? userAnswer; // ユーザーが選んだ回答

  WordTestQuestion({required this.product, required this.options});

  bool get isCorrect => userAnswer == product.name;
}
