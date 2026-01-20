import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 使用 characters 包准确限制字符数的输入格式化器
class CharacterLengthLimitingFormatter extends TextInputFormatter {
  final int maxLength;

  CharacterLengthLimitingFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    final newTextCharacters = newText.characters;

    if (newTextCharacters.length <= maxLength) {
      return newValue;
    }

    // 如果超过限制，截取到最大长度
    final truncated = newTextCharacters.take(maxLength);
    final truncatedText = truncated.string;

    return TextEditingValue(
      text: truncatedText,
      selection: TextSelection.collapsed(offset: truncatedText.length),
    );
  }
}
