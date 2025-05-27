import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/checkedQuestionsProvider.dart';
import '../../../provider/mistakeCountsProvider.dart';
import '../../../provider/productsProvider.dart';
import '../../../utility/Product.dart';
import '../../../utility/WordTestQuestion.dart';
import '../../../utility/generateQuizQuestions.dart';
import '../word_test/WordTestResultPage.dart';


/// ---------------------------------------------------------------------------
/// CheckboxTestPage
/// ---------------------------------------------------------------------------
/// 登録されたチェック対象単語のみを対象としたクイズテスト画面です。
/// 通常の単語テストと類似していますが、チェックボックスにより選ばれた問題だけを
/// 抽出してクイズ問題として出題します。
///
class CheckboxTestPage extends ConsumerStatefulWidget {
  const CheckboxTestPage({super.key});

  @override
  ConsumerState<CheckboxTestPage> createState() => _CheckboxTestPageState();
}

//////////////////////////////////////////////
// _CheckboxTestPageState
//////////////////////////////////////////////
// CheckboxTestPage の内部状態を管理し、以下の役割を持ちます：
// ・チェック済み単語から問題用のクイズリストを生成する（_generateQuiz()）
// ・ユーザーの各問題への回答を受け付け、正誤判定を行う
// ・問題番号と全体の進行状況を管理し、回答後、1秒後に次の問題または結果画面へ遷移する
class _CheckboxTestPageState extends ConsumerState<CheckboxTestPage> {
  List<WordTestQuestion> quiz = []; // 出題対象のクイズ問題リスト
  int currentQuestionIndex = 0; // 現在解答中の問題番号
  bool _isAnswered = false; // 現在の問題に対して回答済みか否か

  /// _generateQuiz()
  /// チェック済み単語だけを抽出し、そこからランダムに quizCount 問のクイズ問題を作成する。
  void _generateQuiz(List<Product> products, Set<String> checked) {
    final filteredProducts =
        products.where((p) => checked.contains(p.name)).toList();
    if (filteredProducts.isEmpty) return; // チェック済みがなければ何も生成しない
    quiz = generateQuizQuestions(filteredProducts, products, quizCount: 10);
    currentQuestionIndex = 0;
    _isAnswered = false;
  }

  @override
  Widget build(BuildContext context) {
    // プロバイダーから全単語情報とチェック済み単語リストを取得
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
          // クイズ問題が空の場合、チェック済み商品から問題を生成
          if (quiz.isEmpty) _generateQuiz(products, checked);
          if (quiz.isEmpty) {
            return const Center(child: Text("チェックされた問題がありません"));
          }
          final currentQuestion = quiz[currentQuestionIndex];
          return Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 画面上部に「問題 ○/○」を表示
                Text(
                  "問題 ${currentQuestionIndex + 1} / ${quiz.length}",
                  style: TextStyle(
                    fontSize: context.fontSizeExtraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // クイズ問題として出題する、単語の説明文を表示
                Text(
                  "問題：${currentQuestion.product.description}",
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
                const SizedBox(height: 24),
                // 回答選択肢をボタン化して横並び（正解の場合は緑、不正解なら赤で表示）
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
                    margin:
                        EdgeInsets.symmetric(vertical: context.paddingSmall),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                      ),
                      onPressed: currentQuestion.userAnswer == null
                          ? () async {
                              // すでに処理済みであれば何もしない
                              if (_isAnswered) return;
                              _isAnswered = true; // 以降のタップをブロック

                              // ユーザーが選択肢をタップした時の処理
                              setState(() {
                                currentQuestion.userAnswer = option;
                              });
                              // 不正解の場合、ミス回数をカウントアップ
                              if (!currentQuestion.isCorrect) {
                                await ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
                              // 1秒後に次の問題へ遷移。最後なら結果画面へ
                              await Future.delayed(const Duration(seconds: 1));
                              if (currentQuestionIndex < quiz.length - 1) {
                                setState(() {
                                  currentQuestionIndex++;
                                  _isAnswered = false; // 次の問題開始時にリセット
                                });
                              } else {
                                if (!context.mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WordTestResultPage(
                                      quiz: quiz,
                                      isCheckboxTest: true,
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        option,
                        style: TextStyle(fontSize: context.fontSizeMedium),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // 回答後、正解・不正解のフィードバックメッセージを表示
                if (currentQuestion.userAnswer != null)
                  Text(
                    currentQuestion.isCorrect
                        ? "正解！"
                        : "不正解。正解は ${currentQuestion.product.name} です。",
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
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
