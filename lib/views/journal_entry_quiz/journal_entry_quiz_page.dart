import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sorting_problem.dart';
import '../../utils/journal_entry_quiz_widget.dart';
import '../../providers/journal_entry_problems_provider.dart';
import '../../view_models/quiz_filter_settings.dart';
import 'journal_entry_quiz_result_page.dart';

class JournalEntryQuizPage extends ConsumerStatefulWidget {
  const JournalEntryQuizPage({super.key});

  @override
  JournalEntryQuizPageState createState() => JournalEntryQuizPageState();
}

class JournalEntryQuizPageState extends ConsumerState<JournalEntryQuizPage> {
  int currentIndex = 0;
  bool? lastAnswerCorrect;
  late List<SortingProblem> quizProblems;
  List<bool> answers = [];
  bool isQuizInitialized = false;

  void onQuizSubmitted(bool isCorrect) {
    setState(() {
      lastAnswerCorrect = isCorrect;
      answers.add(isCorrect);
    });
  }

  void nextQuestion() {
    if (currentIndex < quizProblems.length - 1) {
      setState(() {
        currentIndex++;
        lastAnswerCorrect = null;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JournalEntryQuizResultPage(
            quizProblems: quizProblems,
            answers: answers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(journalEntryProblemsProvider);
    // 設定状態を取得
    final settings = ref.watch(quizFilterSettingsProvider);
    // 設定内容に応じたフィルタ条件を決定
    String filter;
    if (settings.includeIndustrial && !settings.includeCommercial) {
      filter = "工業簿記";
    } else if (!settings.includeIndustrial && settings.includeCommercial) {
      filter = "商業簿記";
    } else {
      filter = "ランダム";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("仕訳問題クイズ"),
      ),
      body: problemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("エラー: $error")),
        data: (problems) {
          List<SortingProblem> availableProblems;
          if (filter != "ランダム") {
            availableProblems =
                problems.where((p) => p.bookkeepingType == filter).toList();
          } else {
            availableProblems = problems;
          }
          if (availableProblems.isEmpty) {
            return Center(child: Text("「$filter」の問題はありません"));
          }
          if (!isQuizInitialized) {
            availableProblems.shuffle(Random());
            quizProblems = availableProblems.length >= 10
                ? availableProblems.take(10).toList()
                : availableProblems.toList();
            isQuizInitialized = true;
          }
          final currentProblem = quizProblems[currentIndex];
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 問題番号と問題の種別を表示
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "問題 ${currentIndex + 1} / ${quizProblems.length} (${currentProblem.bookkeepingType})",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (lastAnswerCorrect != null)
                      ElevatedButton(
                        onPressed: nextQuestion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            const Text("次の問題へ", style: TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                JournalEntryQuizWidget(
                  key: ValueKey(currentProblem.id),
                  problem: currentProblem,
                  onSubmitted: onQuizSubmitted,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
