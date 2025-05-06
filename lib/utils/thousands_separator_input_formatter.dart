
// カンマ区切りで金額をフォーマットするTextInputFormatter
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
