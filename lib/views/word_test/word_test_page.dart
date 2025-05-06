import 'package:bookkeeping_vocabulary_notebook/views/word_test/word_test_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../utils/generate_quiz_questions.dart';
import '../../utils/mistake_counts.dart';
import '../../utils/word_quiz/word_test_question.dart';

class WordTestPage extends ConsumerStatefulWidget {
  const WordTestPage({super.key});

  @override
  ConsumerState<WordTestPage> createState() => _WordTestPageState();
}

class _WordTestPageState extends ConsumerState<WordTestPage> {
  List<WordTestQuestion> quiz = [];
  int currentQuestionIndex = 0;

  void _generateQuiz(List<Product> products) {
    quiz = generateQuizQuestions(products, products, quizCount: 10);
    currentQuestionIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("単語テスト"),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
        data: (products) {
          if (quiz.isEmpty) _generateQuiz(products);
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
                              setState(() {
                                currentQuestion.userAnswer = option;
                              });
                              if (!currentQuestion.isCorrect) {
                                // 回答が不正解の場合、ミス回数を更新
                                ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
                              await Future.delayed(const Duration(seconds: 1));
                              if (currentQuestionIndex < quiz.length - 1) {
                                setState(() {
                                  currentQuestionIndex++;
                                });
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WordTestResultPage(quiz: quiz),
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
