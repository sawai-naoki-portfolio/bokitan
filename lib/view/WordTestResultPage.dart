import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/checkedQuestionsProvider.dart';
import '../provider/mistakeCountsProvider.dart';
import '../provider/productsProvider.dart';
import '../utility/Product.dart';
import '../utility/WordTestQuestion.dart';
import 'CheckboxTestPage.dart';
import 'WordTestPage.dart';

/// ---------------------------------------------------------------------------
/// WordTestResultPage
/// ---------------------------------------------------------------------------
/// 単語テスト（クイズ）の結果画面を表示するウィジェットです。
/// ・全体の正解数を表示し、各問題に対して、
///   問題番号、問題文（単語の説明）、ユーザーの回答、正解・不正解の表示、
///   選択肢一覧、累計ミス回数、解説をカード形式で詳細に表示します。
/// ・画面下部にはホームに戻るボタンや、テストの再挑戦ボタンを配置しています。
class WordTestResultPage extends ConsumerWidget {
  final List<WordTestQuestion> quiz; // 出題されたクイズ問題リスト
  final bool isCheckboxTest; // チェックボックステストかどうかのフラグ

  const WordTestResultPage({
    super.key,
    required this.quiz,
    this.isCheckboxTest = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 正解数を集計
    int correctCount = quiz.where((q) => q.isCorrect).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("テスト結果"),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.paddingSmall),
        child: Column(
          children: [
            // 結果表示（正解数／総問題数）
            Text(
              "結果：$correctCount / ${quiz.length} 問正解",
              style: TextStyle(
                fontSize: context.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            // 各問題の詳細結果を、ListView.separated でカード形式に表示
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
                        // 問題の詳細および回答結果をグラデーション背景に表示
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
                          padding: EdgeInsets.all(context.paddingSmall),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 問題番号表示
                              Text(
                                "問題 ${index + 1}",
                                style: TextStyle(
                                  fontSize: context.fontSizeExtraLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 問題文（単語の説明）
                              Text(
                                question.product.description,
                                style:
                                    TextStyle(fontSize: context.fontSizeSmall),
                              ),
                              const SizedBox(height: 12),
                              // ユーザーの回答が正解か不正解かを表示するラベル
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: context.paddingSmall,
                                    horizontal: context.paddingMedium),
                                decoration: BoxDecoration(
                                  color: question.isCorrect
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  question.isCorrect ? "正解" : "不正解",
                                  style: TextStyle(
                                    fontSize: context.fontSizeMedium,
                                    fontWeight: FontWeight.bold,
                                    color: question.isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // ユーザーの回答と正解を比較して表示
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
                                      style: TextStyle(
                                          fontSize: context.fontSizeMedium,
                                          color: Colors.black87),
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
                                        style: TextStyle(
                                            fontSize: context.fontSizeMedium,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 選択肢一覧を表示（ActionChip 形式）
                              Text(
                                "選択肢:",
                                style: TextStyle(
                                  fontSize: context.fontSizeMedium,
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
                                        style: TextStyle(
                                            fontSize: context.fontSizeMedium)),
                                    backgroundColor: Colors.blueAccent
                                        .withValues(alpha: 0.1),
                                    labelStyle: const TextStyle(
                                        color: Colors.blueAccent),
                                    onPressed: () async {
                                      // 選択肢をタップすると、その単語の詳細情報をダイアログで表示
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
                                      if (!context.mounted) return;
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
                              // 累計ミス回数を表示（フィードバック用）
                              Consumer(builder: (context, ref, child) {
                                final mistakeCounts =
                                    ref.watch(mistakeCountsProvider);
                                final mistakeCount =
                                    mistakeCounts[question.product.name] ?? 0;
                                return Text(
                                  "累計ミス回数: $mistakeCount 回",
                                  style: TextStyle(
                                      fontSize: context.fontSizeExtraSmall,
                                      color: Colors.grey),
                                );
                              }),
                            ],
                          ),
                        ),
                        // カード右上にチェックボックスを配置して「チェック済み」を設定できる
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
            const SizedBox(height: 5),
            // 下部のボタン群：ホームに戻る／再挑戦ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: context.paddingSmall,
                        horizontal: context.paddingMedium),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    // ホームに戻る（スタックの先頭まで戻る）
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: Text("ホームに戻る",
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: context.paddingSmall,
                        horizontal: context.paddingMedium),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    // テストの再挑戦：チェックボックステストか否かで遷移先を切り替え
                    if (isCheckboxTest) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckboxTestPage()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WordTestPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text("もう一度",
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
