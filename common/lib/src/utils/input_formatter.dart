import 'dart:math';

import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(' ', '');
    digitsOnly = digitsOnly.substring(0, min(digitsOnly.length, 11));
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if ((i == 2 || i == 6) && i != digitsOnly.length - 1) {
        buffer.write(' ');
      }
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class BankCardNumberFormatter extends TextInputFormatter {
  const BankCardNumberFormatter({this.groupSize = 4, this.separator = ' ', this.maxLength = 19});

  final int groupSize;
  final String separator;
  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text.replaceAll(separator, '');
    final newText = newValue.text.replaceAll(separator, '');

    if (oldText == newText) {
      return newValue;
    }

    String digitsOnly = newText.replaceAll(RegExp(r'\D'), '');
    digitsOnly = digitsOnly.substring(0, min(digitsOnly.length, maxLength));

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      final isLast = i == digitsOnly.length - 1;
      if (!isLast && (i + 1) % groupSize == 0) {
        buffer.write(separator);
      }
    }

    final formatted = buffer.toString();

    // 处理光标位置（根据空格偏移自动调整）
    int offset = formatted.length;
    final nonFormattedCursorPos = newValue.selection.baseOffset;
    int spaceCount = 0;

    for (int i = 0; i < formatted.length && i < nonFormattedCursorPos + spaceCount; i++) {
      if (formatted[i] == separator) {
        spaceCount++;
      }
    }

    offset = (nonFormattedCursorPos + spaceCount).clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class IdCardNumberFormatter extends TextInputFormatter {
  const IdCardNumberFormatter({this.maxLength = 18});

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.toUpperCase();

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && buffer.length < maxLength; i++) {
      final char = text[i];
      if (RegExp(r'\d').hasMatch(char)) {
        buffer.write(char);
      } else if ((char == 'X' || char == 'x') && buffer.length == 17) {
        buffer.write('X');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  const DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String value = newValue.text;

    // 如果输入的是 ".12"，自动补成 "0.12"
    if (value.startsWith('.') && value.length > 1) {
      value = '0$value';
    }

    // 仅允许一个小数点，去掉多余的小数点
    final dotIndex = value.indexOf('.');
    if (dotIndex != -1) {
      final beforeDot = value.substring(0, dotIndex + 1);
      final afterDot = value.substring(dotIndex + 1).replaceAll('.', '');

      value = beforeDot + afterDot;

      // 限制小数位数
      if (afterDot.length > decimalRange) {
        value = beforeDot + afterDot.substring(0, decimalRange);
      }
    }

    // 只允许数字和小数点
    final valid = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (!valid.hasMatch(value)) {
      return oldValue;
    }

    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
