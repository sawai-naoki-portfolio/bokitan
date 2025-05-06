import 'package:bookkeeping_vocabulary_notebook/views/word_test/word_test_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../utils/mistake_counts.dart';
import '../../providers/checked_questions_provider.dart';
import '../../utils/word_quiz/word_test_question.dart';
import '../checked_questions/check_test_page.dart';

class WordTestResultPage extends ConsumerWidget {
  final List<WordTestQuestion> quiz;
  final bool isCheckboxTest; // チェックボックス問題からのテストかどうかのフラグ

  const WordTestResultPage({
    super.key,
    required this.quiz,
    this.isCheckboxTest = false, // デフォルトは単語テストとして扱う
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int correctCount = quiz.where((q) => q.isCorrect).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("テスト結果"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "結果：$correctCount / ${quiz.length} 問正解",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemCount: quiz.length,
                itemBuilder: (context, index) {
                  final question = quiz[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: question.isCorrect
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE8F5E9),
                                      Color(0xFFC8E6C9)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFFEBEE),
                                      Color(0xFFFFCDD2)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "問題 ${index + 1}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                question.product.description,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: question.isCorrect
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  question.isCorrect ? "正解" : "不正解",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: question.isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "あなたの回答: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: "${question.userAnswer}",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.black87),
                                    ),
                                    if (!question.isCorrect) ...[
                                      const TextSpan(
                                        text: "\n正解: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      TextSpan(
                                        text: question.product.name,
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.green),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "選択肢:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: question.options.map((option) {
                                  return ActionChip(
                                    label: Text(option,
                                        style: const TextStyle(fontSize: 16)),
                                    backgroundColor:
                                        Colors.blueAccent.withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                        color: Colors.blueAccent),
                                    onPressed: () async {
                                      final allProducts = await ref
                                          .read(productsProvider.future);
                                      final optionProduct =
                                          allProducts.firstWhere(
                                        (p) => p.name == option,
                                        orElse: () => Product(
                                            name: option,
                                            yomigana: "",
                                            description: "説明がありません",
                                            category: ''),
                                      );
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(option),
                                          content:
                                              Text(optionProduct.description),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("閉じる"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              Consumer(builder: (context, ref, child) {
                                final mistakeCounts =
                                    ref.watch(mistakeCountsProvider);
                                final mistakeCount =
                                    mistakeCounts[question.product.name] ?? 0;
                                return Text(
                                  "累計ミス回数: $mistakeCount 回",
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                );
                              }),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final isChecked = ref
                                  .watch(checkedQuestionsProvider)
                                  .contains(question.product.name);
                              return Checkbox(
                                value: isChecked,
                                onChanged: (bool? newVal) async {
                                  await ref
                                      .read(checkedQuestionsProvider.notifier)
                                      .toggle(question.product.name);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            // ホームへ戻るボタンなど
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text("ホームに戻る", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    // 遷移元に応じて画面を分岐
                    if (isCheckboxTest) {
                      // チェックボックス問題から遷移してきたときは、
                      // 出題数も同じ設定（例：generateQuizQuestionsで指定している件数）にして再度チェックボックス問題へ
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckTestPage()),
                      );
                    } else {
                      // 単語テストの場合
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WordTestPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("もう一度", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
