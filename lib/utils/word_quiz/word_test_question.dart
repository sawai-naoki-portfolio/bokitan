import '../../models/product.dart';

/// 単語テスト用のクイズ問題クラス
class WordTestQuestion {
  final Product product;
  final List<String> options;
  String? userAnswer; //ユーザーが選んだ回答

  WordTestQuestion({required this.product, required this.options});

  bool get isCorrect => userAnswer == product.name;
}
