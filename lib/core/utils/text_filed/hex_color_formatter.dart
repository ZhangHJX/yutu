import 'color_value_formatter.dart';

/// 简化的颜色输入格式化器（只支持 #RRGGBB 格式，6位）
class HexColorFormatter extends ColorValueFormatter {
  const HexColorFormatter()
    : super(
        maxLength: 8, // # + 6位
        toUpperCase: true,
        minLength: 1,
      );
}
