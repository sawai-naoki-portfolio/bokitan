import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// カンマ区切りで金額をフォーマットするTextInputFormatter
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 空の場合はそのまま返す
    if (newValue.text.isEmpty) return newValue;
    // 数字以外の文字（カンマなど）を除去
    String numericString = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (numericString.isEmpty) return newValue;
    // 数字があればintに変換し、フォーマットする
    final int value = int.parse(numericString);
    final String newText = _formatter.format(value);

    // カーソル位置は末尾に固定（必要に応じて調整可）
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// 設定用モデル、プロバイダー、永続化関数はそのまま
class QuizFilterSettings {
  final bool includeIndustrial; // 工業簿記を含むか
  final bool includeCommercial; // 商業簿記を含むか

  QuizFilterSettings({
    required this.includeIndustrial,
    required this.includeCommercial,
  });
}

final quizFilterSettingsProvider = StateProvider<QuizFilterSettings>(
  (ref) => QuizFilterSettings(includeIndustrial: true, includeCommercial: true),
);

Future<QuizFilterSettings> loadQuizFilterSettings() async {
  final prefs = await SharedPreferences.getInstance();
  bool includeIndustrial = prefs.getBool("quiz_include_industrial") ?? true;
  bool includeCommercial = prefs.getBool("quiz_include_commercial") ?? true;
  return QuizFilterSettings(
    includeIndustrial: includeIndustrial,
    includeCommercial: includeCommercial,
  );
}

Future<void> saveQuizFilterSettings(QuizFilterSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("quiz_include_industrial", settings.includeIndustrial);
  await prefs.setBool("quiz_include_commercial", settings.includeCommercial);
}

/// 各仕訳の正解エントリーを表す
class JournalEntry {
  final String side; // 「借方」または「貸方」
  final String account; // 勘定科目
  final int amount; // 金額

  JournalEntry({
    required this.side,
    required this.account,
    required this.amount,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      side: json['side'] as String,
      account: json['account'] as String,
      amount: json['amount'] as int,
    );
  }
}

/// 仕訳問題（取引）のデータモデル
class SortingProblem {
  final String id;
  final String transactionDate;
  final String description;
  final List<JournalEntry> entries;
  final String feedback;
  final String bookkeepingType; // 新たに追加

  SortingProblem({
    required this.id,
    required this.transactionDate,
    required this.description,
    required this.entries,
    required this.feedback,
    required this.bookkeepingType,
  });

  factory SortingProblem.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List;
    return SortingProblem(
      id: json['id'] as String,
      transactionDate: json['transaction_date'] as String,
      description: json['description'] as String,
      entries: entriesJson.map((e) => JournalEntry.fromJson(e)).toList(),
      feedback: json['feedback'] as String,
      bookkeepingType: json['bookkeepingType'] as String, // ここで読み込む
    );
  }
}

/// JSONファイル（assets/siwake.json）から仕訳問題リストを読み込むProvider
final sortingProblemsProvider =
    FutureProvider<List<SortingProblem>>((ref) async {
  final data = await rootBundle.loadString('assets/siwake.json');
  final List<dynamic> jsonResult = jsonDecode(data);
  return jsonResult.map((json) => SortingProblem.fromJson(json)).toList();
});

/// ─────────────────────────────────────────────
/// ユーザーが問題に解答するウィジェット【左右レイアウト：左→借方、右→貸方】
/// ─────────────────────────────────────────────
class JournalEntryQuizWidget extends StatefulWidget {
  final SortingProblem problem;
  final Function(bool) onSubmitted; // 正誤結果のコールバック

  const JournalEntryQuizWidget({
    super.key,
    required this.problem,
    required this.onSubmitted,
  });

  @override
  State<JournalEntryQuizWidget> createState() => _JournalEntryQuizWidgetState();
}

class _JournalEntryQuizWidgetState extends State<JournalEntryQuizWidget> {
  // 正解の仕訳を「借方」と「貸方」に分割
  late final List<JournalEntry> debitAnswers;
  late final List<JournalEntry> creditAnswers;

  // すべてのエントリーから共通の勘定科目リストを作成
  late final List<String> commonAccountOptions;

  // ユーザー入力（借方）
  late List<String?> userDebitAccounts;
  late List<TextEditingController> debitAmountControllers;

  // ユーザー入力（貸方）
  late List<String?> userCreditAccounts;
  late List<TextEditingController> creditAmountControllers;

  bool? isAnswerCorrect;

  @override
  void initState() {
    super.initState();
    debitAnswers =
        widget.problem.entries.where((entry) => entry.side == "借方").toList();
    creditAnswers =
        widget.problem.entries.where((entry) => entry.side == "貸方").toList();
    // 借方・貸方共通の勘定科目リスト（重複除外）
    commonAccountOptions =
        widget.problem.entries.map((e) => e.account).toSet().toList();

    userDebitAccounts = List.filled(debitAnswers.length, null);
    debitAmountControllers =
        List.generate(debitAnswers.length, (_) => TextEditingController());

    userCreditAccounts = List.filled(creditAnswers.length, null);
    creditAmountControllers =
        List.generate(creditAnswers.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var ctrl in debitAmountControllers) {
      ctrl.dispose();
    }
    for (var ctrl in creditAmountControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void submitAnswer() {
    // 入力漏れチェック（借方）
    for (int i = 0; i < userDebitAccounts.length; i++) {
      if (userDebitAccounts[i] == null ||
          debitAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("借方のすべての項目を選択してください")),
        );
        return;
      }
    }
    // 入力漏れチェック（貸方）
    for (int i = 0; i < userCreditAccounts.length; i++) {
      if (userCreditAccounts[i] == null ||
          creditAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("貸方のすべての項目を選択してください")),
        );
        return;
      }
    }

    List<Map<String, dynamic>> userDebitList = [];
    for (int i = 0; i < userDebitAccounts.length; i++) {
      // 金額入力フィールドのテキストからカンマを取り除く
      int? amount = int.tryParse(
        debitAmountControllers[i].text.trim().replaceAll(',', ''),
      );
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("借方：金額は数字で入力してください")),
        );
        return;
      }
      userDebitList.add({
        'account': userDebitAccounts[i],
        'amount': amount,
      });
    }

    List<Map<String, dynamic>> userCreditList = [];
    for (int i = 0; i < userCreditAccounts.length; i++) {
      int? amount = int.tryParse(
        creditAmountControllers[i].text.trim().replaceAll(',', ''),
      );
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("貸方：金額は数字で入力してください")),
        );
        return;
      }
      userCreditList.add({
        'account': userCreditAccounts[i],
        'amount': amount,
      });
    }

    List<Map<String, dynamic>> correctDebitList = debitAnswers
        .map((entry) => {
              'account': entry.account,
              'amount': entry.amount,
            })
        .toList();
    List<Map<String, dynamic>> correctCreditList = creditAnswers
        .map((entry) => {
              'account': entry.account,
              'amount': entry.amount,
            })
        .toList();

    bool debitCorrect = _isListEqual(userDebitList, correctDebitList);
    bool creditCorrect = _isListEqual(userCreditList, correctCreditList);

    setState(() {
      isAnswerCorrect = debitCorrect && creditCorrect;
    });
    widget.onSubmitted(isAnswerCorrect!);
  }

  bool _isListEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    List<Map<String, dynamic>> temp = List.from(list2);
    for (var item in list1) {
      int index = temp.indexWhere((e) =>
          e['account'] == item['account'] && e['amount'] == item['amount']);
      if (index == -1) {
        return false;
      } else {
        temp.removeAt(index);
      }
    }
    return temp.isEmpty;
  } // 左側（借方エントリー）のウィジェット

  Widget _buildDebitEntry(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ここで勘定科目の DropdownButtonFormField のコードは変わらず
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "勘定科目",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: userDebitAccounts[index],
            isExpanded: true,
            items: commonAccountOptions
                .map((account) => DropdownMenuItem(
                      value: account,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                userDebitAccounts[index] = val;
              });
            },
          ),
          const SizedBox(height: 6),
          // 金額入力フィールドに電卓アイコンを追加
          TextField(
            controller: debitAmountControllers[index],
            decoration: InputDecoration(
              labelText: "金額",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  // 現在入力されている内容（カンマを除去して数値に変換）
                  double initialValue = double.tryParse(
                          debitAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  // 電卓ウィジェットをモーダルボトムシートで表示
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
                    // 結果をカンマ区切りでフォーマットしてフィールドに反映
                    debitAmountControllers[index].text =
                        NumberFormat('#,###').format(result);
                  }
                },
              ),
            ),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

// 右側（貸方エントリー）のウィジェット
  Widget _buildCreditEntry(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "勘定科目",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: userCreditAccounts[index],
            isExpanded: true,
            items: commonAccountOptions
                .map((account) => DropdownMenuItem(
                      value: account,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                userCreditAccounts[index] = val;
              });
            },
          ),
          const SizedBox(height: 6),
          // 貸方金額入力フィールドに Calculator を実装
          TextField(
            controller: creditAmountControllers[index],
            decoration: InputDecoration(
              labelText: "金額",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  // 入力中のテキストからカンマを除去して数値に変換
                  double initialValue = double.tryParse(
                          creditAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  // CalculatorWidget をモーダルボトムシートとして表示
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
                    // 結果をカンマ付きでフォーマットしてテキストフィールドに反映
                    creditAmountControllers[index].text =
                        NumberFormat('#,###').format(result);
                  }
                },
              ),
            ),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          widget.problem.description,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("借方",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(thickness: 2),
                  Column(
                    children: List.generate(debitAnswers.length,
                        (index) => _buildDebitEntry(index)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("貸方",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(thickness: 2),
                  Column(
                    children: List.generate(creditAnswers.length,
                        (index) => _buildCreditEntry(index)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (isAnswerCorrect != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAnswerCorrect! ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAnswerCorrect! ? Colors.green : Colors.red,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnswerCorrect! ? "正解です！" : "不正解です",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAnswerCorrect! ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text("正解仕訳【借方】",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...debitAnswers
                    .map((entry) => Text("${entry.account}  ¥${entry.amount}")),
                const SizedBox(height: 4),
                const Text("正解仕訳【貸方】",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...creditAnswers
                    .map((entry) => Text("${entry.account}  ¥${entry.amount}")),
                const SizedBox(height: 12),
                const Text("解説", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.problem.feedback),
              ],
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isAnswerCorrect == null
              ? () {
                  // キーボードを閉じる
                  FocusScope.of(context).unfocus();
                  submitAnswer();
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Center(
            child: Text(
              "回答を提出",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

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
          builder: (_) => SortingQuizResultPage(
            quizProblems: quizProblems,
            answers: answers,
          ),
        ),
      );
    }
  }

  // Google Form の公開URL（ご利用のURLに置き換えてください）
  final String feedbackUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSevGyY5tye6g36xIz6CW25iBi4BJfHk70ss7l3_S0O6HyYmiA/viewform?usp=dialog';

  Future<void> _launchFeedbackForm(BuildContext context) async {
    final Uri url = Uri.parse(feedbackUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("フィードバックフォームを開けませんでした")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(sortingProblemsProvider);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_support),
            tooltip: "お問い合わせ",
            onPressed: () {
              // 現在の問題のIDを取得
              final currentProblemId = quizProblems[currentIndex].id;
              // ローカル状態変数を外側で初期化（dialog内で利用）
              bool isCopied = false;
              // お問い合わせダイアログを StatefullBuilder で表示
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text("お問い合わせ"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "クイズに誤りがある場合は、以下フォームに「問題ID」と「正しい回答」を記載をお願い致します。",
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                border:
                                    Border.all(color: Colors.orange, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.orange),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: SelectableText(
                                      "問題ID: $currentProblemId",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.orange),
                                    tooltip: "コピー",
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: currentProblemId),
                                      );
                                      setState(() {
                                        isCopied = true;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text("問題IDをコピーしました"),
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Googleフォームへ遷移するためのボタンはコピー済みでなければ無効にする
                            TextButton(
                              onPressed: isCopied
                                  ? () => _launchFeedbackForm(context)
                                  : null,
                              child: Text(
                                isCopied
                                    ? "仕訳問題お問い合わせフォームへ移動"
                                    : "問題IDアイコンを押してください",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("閉じる"),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          )
        ],
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

/// ─────────────────────────────────────────────
/// 結果画面【各問題の結果と総合得点を表示】
/// ─────────────────────────────────────────────

class SortingQuizResultPage extends ConsumerWidget {
  final List<SortingProblem> quizProblems;
  final List<bool> answers; // 各問題の正誤結果

  const SortingQuizResultPage({
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

class CalculatorWidget extends StatefulWidget {
  /// CalculatorWidget の初期値は常に 0 からスタート
  final double initialValue;

  const CalculatorWidget({super.key, this.initialValue = 0});

  @override
  CalculatorWidgetState createState() => CalculatorWidgetState();
}

class CalculatorWidgetState extends State<CalculatorWidget> {
  String display = '0';

  @override
  void initState() {
    super.initState();
    display = '0';
  }

  /// 数式の評価結果をフォーマットするヘルパー
  String formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  /// キー押下の処理
  void _onPressed(String key) {
    setState(() {
      if (key == "C") {
        display = "0";
      } else if (key == "DEL") {
        if (display.isNotEmpty) {
          display = display.substring(0, display.length - 1);
          if (display.isEmpty) display = "0";
        }
      } else if (key == "±") {
        if (display.startsWith("-")) {
          display = display.substring(1);
        } else if (display != "0") {
          display = "-$display";
        }
      } else if (key == "=") {
        try {
          Parser p = Parser();
          Expression exp = p.parse(display);
          ContextModel cm = ContextModel();
          double result = exp.evaluate(EvaluationType.REAL, cm);
          // 整数なら小数点以下を省略
          display = formatResult(result);
        } catch (e) {
          display = "Error";
        }
      } else {
        // もし display が "0" または "Error" の場合、数字または小数点入力なら上書き
        if ((display == "0" || display == "Error") &&
            "0123456789.".contains(key)) {
          display = key;
        } else {
          display += key;
        }
      }
    });
  }

  /// キー用のボタンウィジェット
  Widget _buildButton(String label) {
    if (label.isEmpty) return Container();
    return ElevatedButton(
      onPressed: () => _onPressed(label),
      child: Text(
        label,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 5行×4列のキーリスト（最後のキーは空文字にして余白として利用）
    final List<String> keys = [
      "C",
      "±",
      "/",
      "DEL",
      "7",
      "8",
      "9",
      "*",
      "4",
      "5",
      "6",
      "-",
      "1",
      "2",
      "3",
      "+",
      "0",
      ".",
      "=",
      ""
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      height: 500, // ModalBottomSheetに合わせた高さ（調整可能）
      child: Column(
        children: [
          // 入力結果表示部
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: Text(
              display,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const Divider(),
          // キーパッド部分：4列グリッド
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: keys.map((key) => _buildButton(key)).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // 「確定」ボタン：このボタンを押すと現在の計算結果が呼び出し元に返される
          ElevatedButton(
            onPressed: () {
              double result = 0;
              try {
                Parser p = Parser();
                Expression exp = p.parse(display);
                ContextModel cm = ContextModel();
                result = exp.evaluate(EvaluationType.REAL, cm);
              } catch (e) {
                result = 0;
              }
              // 結果のフォーマット
              String formatted = formatResult(result);
              // 呼び出し元に返す
              Navigator.pop(context, double.tryParse(formatted) ?? 0);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text(
              "確定",
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
