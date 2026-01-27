import 'package:flutter/services.dart';

/// 只允许 0-100 的整数输入：
/// - 只能输入数字
/// - 最多 3 位
/// - >100 自动变为 100
class InputNumberFormatter extends TextInputFormatter {
  const InputNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // 允许清空
    if (text.isEmpty) return newValue;

    // 只保留数字（如果你已经叠加了 FilteringTextInputFormatter.digitsOnly，这里也可以不写）
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return oldValue;
    }

    // 最多 3 位
    var clipped = digitsOnly.length > 3
        ? digitsOnly.substring(0, 3)
        : digitsOnly;

    // 数值限制到 <= 100
    final numVal = int.tryParse(clipped) ?? 0;
    final capped = numVal > 100 ? '100' : clipped;

    // 自动变为 100 / 截断后，把光标放到末尾（最直观）
    return TextEditingValue(
      text: capped,
      selection: TextSelection.collapsed(offset: capped.length),
      composing: TextRange.empty,
    );
  }
}
