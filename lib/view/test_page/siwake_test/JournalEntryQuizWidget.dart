// ============================================================================
// JournalEntryQuizWidget
// -----------------------------------------------------------------------------
// JournalEntryQuizWidget は、仕訳問題のクイズ画面として使用されるウィジェットです。
// ・SortingProblem を受け取り、ユーザーに対して正解の仕訳エントリー（借方／貸方）の
//   入力を求めます。
// ・onSubmitted コールバックにより、正解か否かの結果を親ウィジェットに通知します。
// ============================================================================
import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/CalculatorWidget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utility/JournalEntry.dart';
import '../../../utility/SortingProblem.dart';
import '../../../utility/ThousandsSeparatorInputFormatter.dart';

class JournalEntryQuizWidget extends StatefulWidget {
  final SortingProblem problem;
  final Function(bool) onSubmitted; // クイズ回答が提出された際に正誤結果を通知

  const JournalEntryQuizWidget({
    super.key,
    required this.problem,
    required this.onSubmitted,
  });

  @override
  State<JournalEntryQuizWidget> createState() => _JournalEntryQuizWidgetState();
}

// ============================================================================
// _JournalEntryQuizWidgetState
// -----------------------------------------------------------------------------
// _JournalEntryQuizWidgetState では、JournalEntryQuizWidget の内部状態を管理します。
// ・問題文に応じた借方・貸方の正解エントリー（debitAnswers, creditAnswers）を抽出
// ・ユーザーが入力する各勘定科目と金額の状態を個別に管理（userDebitAccounts, debitAmountControllers 等）
// ・submitAnswer メソッドで、ユーザーの入力内容と正解リストを比較し、正誤判定を行います。
// ・また、各入力ウィジェット（_buildDebitEntry, _buildCreditEntry）を構築します。
// ============================================================================
class _JournalEntryQuizWidgetState extends State<JournalEntryQuizWidget> {
  // 正解の借方・貸方エントリー
  late final List<JournalEntry> debitAnswers;
  late final List<JournalEntry> creditAnswers;

  // 問題内で共通して利用できる勘定科目の候補リスト
  late final List<String> commonAccountOptions;

  // ユーザーが入力する借方エントリーの各項目（勘定科目）管理
  late List<String?> userDebitAccounts;

  // 借方エントリーの金額入力用テキストコントローラー
  late List<TextEditingController> debitAmountControllers;

  // ユーザーが入力する貸方エントリーの各項目（勘定科目）管理
  late List<String?> userCreditAccounts;

  // 貸方エントリーの金額入力用テキストコントローラー
  late List<TextEditingController> creditAmountControllers;

  // 回答の正誤状態（null:未回答、true:正解、false:不正解）
  bool? isAnswerCorrect;

  @override
  void initState() {
    super.initState();
    // 問題文から「借方」エントリーと「貸方」エントリーを抽出
    debitAnswers =
        widget.problem.entries.where((entry) => entry.side == "借方").toList();
    creditAnswers =
        widget.problem.entries.where((entry) => entry.side == "貸方").toList();

    // 問題に含まれる全勘定科目の候補（重複を除く）
    commonAccountOptions =
        widget.problem.entries.map((e) => e.account).toSet().toList();

    // ユーザーへの初期入力（nullで初期化）
    userDebitAccounts = List.filled(debitAnswers.length, null);
    // 借方の金額入力コントローラーを生成
    debitAmountControllers =
        List.generate(debitAnswers.length, (_) => TextEditingController());

    // 貸方の入力も同様に初期化
    userCreditAccounts = List.filled(creditAnswers.length, null);
    creditAmountControllers =
        List.generate(creditAnswers.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    // 各コントローラーを破棄してリソースを解放
    for (var ctrl in debitAmountControllers) {
      ctrl.dispose();
    }
    for (var ctrl in creditAmountControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ========================================================================
  // submitAnswer
  // ------------------------------------------------------------------------
  // ユーザーの入力内容が全て入力されているかチェック後、
  // 入力された借方・貸方それぞれのリストと正解リストを比較し正誤判定を行います。
  // 正誤判定結果は、親ウィジェットの onSubmitted コールバックで通知します。
  // ========================================================================
  void submitAnswer() {
    // 借方の各エントリーが入力済みかどうかチェック
    for (int i = 0; i < userDebitAccounts.length; i++) {
      if (userDebitAccounts[i] == null ||
          debitAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("借方のすべての項目を選択してください")),
        );
        return;
      }
    }

    // 貸方の各エントリーについてもチェック
    for (int i = 0; i < userCreditAccounts.length; i++) {
      if (userCreditAccounts[i] == null ||
          creditAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("貸方のすべての項目を選択してください")),
        );
        return;
      }
    }

    // ユーザーが入力した借方エントリーのリストに変換（勘定科目＋金額）
    List<Map<String, dynamic>> userDebitList = [];
    for (int i = 0; i < userDebitAccounts.length; i++) {
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

    // ユーザーが入力した貸方エントリーのリストに変換
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

    // 正解の借方・貸方リストも Map の形に変換
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

    // 借方と貸方それぞれの正誤判定
    bool debitCorrect = _isListEqual(userDebitList, correctDebitList);
    bool creditCorrect = _isListEqual(userCreditList, correctCreditList);

    // 両方正解であれば最終的な正誤結果は true
    setState(() {
      isAnswerCorrect = debitCorrect && creditCorrect;
    });
    // 親ウィジェットに結果を通知
    widget.onSubmitted(isAnswerCorrect!);
  }

  // ========================================================================
  // _isListEqual
  // ------------------------------------------------------------------------
  // 2 つの Map のリストが同一内容かどうかを比較します。
  // 順序は問いませんが、各要素（勘定科目と金額の組）が同じであれば true を返します。
  // ========================================================================
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
  }

  // ========================================================================
  // _buildDebitEntry
  // ------------------------------------------------------------------------
  // 指定された index の借方入力項目のウィジェットを構築します。
  // ・DropdownButtonFormField: 勘定科目の選択
  // ・TextField: 金額の入力（カンマ区切りに自動フォーマット）
// ========================================================================
  Widget _buildDebitEntry(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.paddingMedium),
      padding: EdgeInsets.all(context.paddingMedium),
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
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: userDebitAccounts[index],
            isExpanded: true,
            // ユーザーが選択可能な勘定科目一覧（共通候補リスト）
            items: commonAccountOptions
                .map((account) => DropdownMenuItem(
                      value: account,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account,
                          style: TextStyle(fontSize: context.fontSizeMedium),
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
          TextField(
            controller: debitAmountControllers[index],
            decoration: InputDecoration(
              labelText: "金額",
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // 計算結果を入力するための電卓アイコン
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  double initialValue = double.tryParse(
                          debitAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
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

  // ========================================================================
  // _buildCreditEntry
  // ------------------------------------------------------------------------
  // 指定された index の貸方入力項目のウィジェットを構築します。
// 借方と同様に、勘定科目の選択と金額の入力フィールドから構成されます。
// ========================================================================
  Widget _buildCreditEntry(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.paddingMedium),
      padding: EdgeInsets.all(context.paddingMedium),
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
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
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
                          style: TextStyle(fontSize: context.fontSizeMedium),
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
          TextField(
            controller: creditAmountControllers[index],
            decoration: InputDecoration(
              labelText: "金額",
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  double initialValue = double.tryParse(
                          creditAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
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
          style: TextStyle(
              fontSize: context.fontSizeMedium, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("借方",
                      style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.bold)),
                  const Divider(thickness: 2),
                  // 借方入力フィールド群の生成
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
                  Text("貸方",
                      style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.bold)),
                  const Divider(thickness: 2),
                  // 貸方入力フィールド群の生成
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
        // 回答結果表示（正誤のフィードバックと正解仕訳、解説）
        if (isAnswerCorrect != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.paddingMedium),
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
                    fontSize: context.fontSizeMedium,
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
                  FocusScope.of(context).unfocus();
                  submitAnswer();
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              "回答を提出",
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
        ),
      ],
    );
  }
}
