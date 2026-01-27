import 'package:common/common.dart';
import 'package:flutter/services.dart';

class MaxValueFormatter extends TextInputFormatter {
  MaxValueFormatter(this.max, this.from);

  final double max;
  final String from;
  bool _showing = false;

  void _toastOnce(String msg) {
    if (_showing) return;
    _showing = true;
    String tips = '输入值不能大于${max.toInt()}';
    if (from == "fontSize") {
      tips = '字号不能大于${max.toInt()}';
    }
    showToast(tips).whenComplete(() {
      _showing = false;
    });
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.trim();

    // 允许清空
    if (text.isEmpty) return newValue;

    // 只允许数字（可按需要放开小数：r'^\d+(\.\d+)?$'）
    final ok = RegExp(r'^\d+$').hasMatch(text);
    if (!ok) return oldValue;

    final v = int.tryParse(text);
    if (v == null) return oldValue;

    if (v > max) {
      _toastOnce('输入值不能大于 ${max.toInt()}');
      return oldValue; // 关键：超出就回退，等于“停止输入”
    }
    return newValue;
  }
}
