import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sorting_problem.dart';
import 'journal_entry_quiz_page.dart';

class JournalEntryQuizResultPage extends ConsumerWidget {
  final List<SortingProblem> quizProblems;
  final List<bool> answers; // 各問題の正誤結果

  const JournalEntryQuizResultPage({
    super.key,
    required this.quizProblems,
    required this.answers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int correctCount = answers.where((isCorrect) => isCorrect).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("結果画面"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 総合成績表示
            Text(
              "結果：$correctCount / ${quizProblems.length} 問正解",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            // 各問題の結果をカード形式で表示
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemCount: quizProblems.length,
                itemBuilder: (context, index) {
                  final problem = quizProblems[index];
                  final isCorrect = answers[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isCorrect
                            ? const LinearGradient(
                                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
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
                            problem.description,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isCorrect ? "正解" : "不正解",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          if (!isCorrect) ...[
                            const SizedBox(height: 12),
                            const Text(
                              "正解仕訳【借方】",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...problem.entries
                                .where((e) => e.side == "借方")
                                .map((e) => Text("${e.account}  ¥${e.amount}")),
                            const SizedBox(height: 4),
                            const Text(
                              "正解仕訳【貸方】",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...problem.entries
                                .where((e) => e.side == "貸方")
                                .map((e) => Text("${e.account}  ¥${e.amount}")),
                            const SizedBox(height: 12),
                            const Text(
                              "解説：",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(problem.feedback),
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // 2つのボタンを横に並べる例
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 「ホームに戻る」ボタン：トップに戻る
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text("ホームに戻る", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                // 「もう一度」ボタン：クイズを再挑戦
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const JournalEntryQuizPage()),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("もう一度", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
