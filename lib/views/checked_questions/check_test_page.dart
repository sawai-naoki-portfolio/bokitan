import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../utils/generate_quiz_questions.dart';
import '../../utils/mistake_counts.dart';
import '../../providers/checked_questions_provider.dart';
import '../../utils/word_quiz/word_test_question.dart';
import '../word_test/word_test_result_page.dart';

class CheckTestPage extends ConsumerStatefulWidget {
  const CheckTestPage({super.key});

  @override
  ConsumerState<CheckTestPage> createState() => _CheckTestPageState();
}

class _CheckTestPageState extends ConsumerState<CheckTestPage> {
  List<WordTestQuestion> quiz = [];
  int currentQuestionIndex = 0;

  // 追加：各問題の解答処理を一度だけ実行するためのフラグ
  bool _isAnswered = false;

  void _generateQuiz(List<Product> products, Set<String> checked) {
    final filteredProducts =
        products.where((p) => checked.contains(p.name)).toList();
    if (filteredProducts.isEmpty) return;
    quiz = generateQuizQuestions(filteredProducts, products, quizCount: 10);
    currentQuestionIndex = 0;
    _isAnswered = false; // 新しい問題開始時にフラグをリセット
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final checked = ref.watch(checkedQuestionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("チェックボックス問題"),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
        data: (products) {
          if (quiz.isEmpty) _generateQuiz(products, checked);
          if (quiz.isEmpty) {
            return const Center(child: Text("チェックされた問題がありません"));
          }
          final currentQuestion = quiz[currentQuestionIndex];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "問題 ${currentQuestionIndex + 1} / ${quiz.length}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "問題：${currentQuestion.product.description}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ...currentQuestion.options.map((option) {
                  Color? btnColor;
                  if (currentQuestion.userAnswer != null) {
                    if (option == currentQuestion.product.name) {
                      btnColor = Colors.green;
                    } else if (option == currentQuestion.userAnswer) {
                      btnColor = Colors.red;
                    }
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                      ),
                      onPressed: currentQuestion.userAnswer == null
                          ? () async {
                              // すでに処理済みであれば何もしない
                              if (_isAnswered) return;
                              _isAnswered = true; // 以降のタップをブロック
                              setState(() {
                                currentQuestion.userAnswer = option;
                              });
                              // 不正解の場合は、ここで1回だけミス数を更新
                              if (!currentQuestion.isCorrect) {
                                await ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
                              await Future.delayed(const Duration(seconds: 1));
                              if (currentQuestionIndex < quiz.length - 1) {
                                setState(() {
                                  currentQuestionIndex++;
                                  _isAnswered = false; // 次の問題開始時にリセット
                                });
                              } else {
                                // CheckTestPage内での遷移例
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WordTestResultPage(
                                        quiz: quiz, isCheckboxTest: true),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(option, style: const TextStyle(fontSize: 16)),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                if (currentQuestion.userAnswer != null)
                  Text(
                    currentQuestion.isCorrect
                        ? "正解！"
                        : "不正解。正解は ${currentQuestion.product.name} です。",
                    style: TextStyle(
                      fontSize: 18,
                      color:
                          currentQuestion.isCorrect ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
