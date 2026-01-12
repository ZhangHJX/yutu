import 'package:flutter/services.dart';

class BorderWidthFormatter extends TextInputFormatter {
  final int max;

  BorderWidthFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 允许空值（用户正在删除）
    if (newValue.text.isEmpty) return newValue;

    // 尝试解析数字
    final value = int.tryParse(newValue.text);
    if (value == null) {
      // 非数字，返回旧值（禁止输入）
      return oldValue;
    }

    // 限制最大值
    if (value > max) {
      return oldValue; // 超过最大值，不允许输入
    }

    return newValue;
  }
}
