import 'dart:math';

import 'Product.dart';
import 'WordTestQuestion.dart';

/// ---------------------------------------------------------------------------
/// generateQuizQuestions
/// ─ quizPool（出題対象）と distractorPool（誤答候補）から、指定数のクイズ問題を生成する
/// ---------------------------------------------------------------------------
List<WordTestQuestion> generateQuizQuestions(
    List<Product> quizPool, List<Product> distractorPool,
    {int quizCount = 10}) {
  final random = Random();
  final quizProducts = (List<Product>.from(quizPool)..shuffle(random))
      .take(min(quizCount, quizPool.length))
      .toList();

  return quizProducts.map((product) {
    // distractorPoolから誤答候補を抽出
    List<String> distractors = distractorPool
        .where((p) => p.name != product.name)
        .map((p) => p.name)
        .toList();
    distractors.shuffle(random);

    // 正答と誤答候補を混ぜ、必ず4つの選択肢を用意
    List<String> options = [product.name];
    if (distractors.length >= 3) {
      options.addAll(distractors.take(3));
    } else {
      options.addAll(distractors);
      while (options.length < 4) {
        options.add("選択肢なし");
      }
    }
    options.shuffle(random);
    return WordTestQuestion(product: product, options: options);
  }).toList();
}
