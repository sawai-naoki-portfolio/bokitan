// ============================================================================
// CalculatorWidget
// -----------------------------------------------------------------------------
// CalculatorWidget は、計算機能を提供するモーダルウィジェットです。
// ユーザーはこのウィジェット上で数式入力や数値計算を行い、結果を確定ボタンで
// 呼び出し元へ返します。
// ============================================================================

import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorWidget extends StatefulWidget {
  final double initialValue; // 電卓起動時の初期値

  const CalculatorWidget({super.key, this.initialValue = 0});

  @override
  CalculatorWidgetState createState() => CalculatorWidgetState();
}

// ============================================================================
// CalculatorWidgetState
// -----------------------------------------------------------------------------
// この状態クラスは、CalculatorWidget の内部状態を管理します。
// ・display: 現在の入力内容または計算結果の文字列を保持
// ・_onPressed: 各ボタンタップ時のロジックを実装（クリア、削除、符号反転、計算など）
// ・_buildButton: 各計算ボタンウィジェットを構築します。
// ・build: グリッドレイアウトで計算機の各キーと、確定ボタンを表示します。
// ============================================================================

class CalculatorWidgetState extends State<CalculatorWidget> {
  String display = '0';

  @override
  void initState() {
    super.initState();
    display = '0';
  }

  // 数値が整数なら整数として、そうでなければ小数点以下も含め文字列としてフォーマット
  String formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  // ========================================================================
  // _onPressed
  // ------------------------------------------------------------------------
  // 各キー（"C", "DEL", "±", "=", 数字・演算子）の入力に応じて、
  // display の状態を更新します。例として、クリアなら "0" にリセットし、
  // 削除キーなら末尾の文字を削除、= キーなら評価を行います。
  // ========================================================================
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
          display = formatResult(result);
        } catch (e) {
          display = "Error";
        }
      } else {
        // 初期状態 "0" またはエラー時の入力は、上書きする
        if ((display == "0" || display == "Error") &&
            "0123456789.".contains(key)) {
          display = key;
        } else {
          display += key;
        }
      }
    });
  }

  // ========================================================================
  // _buildButton
  // ------------------------------------------------------------------------
  // 指定されたラベル文字列を持つ計算機のキーを作成するためのヘルパーメソッドです。
  // キーが空文字なら空の Container を返します（レイアウト調整のため）。
  // ========================================================================
  Widget _buildButton(String label) {
    if (label.isEmpty) return Container();
    return ElevatedButton(
      onPressed: () => _onPressed(label),
      child: Text(
        label,
        style: TextStyle(fontSize: context.fontSizeMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 計算機上に表示するキーの文字列リスト
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
      padding: EdgeInsets.all(context.paddingMedium),
      height: 500,
      child: Column(
        children: [
          // 計算結果または入力数式を表示する領域
          Container(
            padding: EdgeInsets.all(context.paddingMedium),
            alignment: Alignment.centerRight,
            child: Text(
              display,
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
          const Divider(),
          // キーを 4 カラムのグリッド表示で配置
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
          // 下部の「確定」ボタンを押すと、計算結果を呼び出し元へ返す
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
              String formatted = formatResult(result);
              Navigator.pop(context, double.tryParse(formatted) ?? 0);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              "確定",
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
        ],
      ),
    );
  }
} ///////////////////////////////////////////////////////////////
