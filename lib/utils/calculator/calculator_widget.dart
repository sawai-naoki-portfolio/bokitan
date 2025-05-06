import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

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
