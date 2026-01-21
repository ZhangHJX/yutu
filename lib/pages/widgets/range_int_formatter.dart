import 'package:flutter/services.dart';

class RangeIntFormatter extends TextInputFormatter {
  RangeIntFormatter({required this.min, required this.max});
  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue; // 允许清空

    final v = int.tryParse(text);
    if (v == null) return oldValue; // 非数字回退
    if (v < min || v > max) return oldValue; // 超范围回退
    return newValue;
  }
}
