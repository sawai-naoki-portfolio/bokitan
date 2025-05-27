import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// ---------------------------------------------------------------------------
/// ThousandsSeparatorInputFormatter
/// ─ この入力フォーマッターは、数字入力中に自動でカンマ区切りのフォーマットに変換します。
/// ---------------------------------------------------------------------------
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 入力が空の場合はそのまま返す
    if (newValue.text.isEmpty) return newValue;

    // 数字以外 (カンマなど) を除去する
    String numericString = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (numericString.isEmpty) return newValue;

    // 文字列を整数に変換し、フォーマット後の文字列を生成
    final int value = int.parse(numericString);
    final String newText = _formatter.format(value);

    // カーソルを常に末尾に設定
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
