import 'dart:math';

import 'package:bookkeeping_vocabulary_notebook/utils/word_quiz/word_test_question.dart';

import '../models/product.dart';

List<WordTestQuestion> generateQuizQuestions(
    List<Product> quizPool, List<Product> distractorPool,
    {int quizCount = 10}) {
  final random = Random();
  final quizProducts = (List<Product>.from(quizPool)..shuffle(random))
      .take(min(quizCount, quizPool.length))
      .toList();
  return quizProducts.map((product) {
    // distractorPool から正解以外の候補を抽出
    List<String> distractors = distractorPool
        .where((p) => p.name != product.name)
        .map((p) => p.name)
        .toList();
    distractors.shuffle(random);

    // 正しい回答とダミー候補から必ず3個取得（足りなければダミーの"選択肢なし"で埋める）
    List<String> options = [product.name];
    if (distractors.length >= 3) {
      options.addAll(distractors.take(3));
    } else {
      options.addAll(distractors);
      // 足りない場合はダミー文言で埋める（必要に応じて適宜変更してください）
      while (options.length < 4) {
        options.add("選択肢なし");
      }
    }
    options.shuffle(random);
    return WordTestQuestion(product: product, options: options);
  }).toList();
}
