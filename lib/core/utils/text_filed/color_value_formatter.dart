import 'package:flutter/services.dart';

/// 颜色值输入格式化器
/// 规则：
/// 1. 必须以 '#' 开头，且 '#' 不能被删除
/// 2. 只允许输入十六进制字符（0-9, A-F, a-f）
/// 3. 支持的格式：
///    - #RGB (3个字符，如 #FFF)
///    - #RRGGBB (6个字符，如 #FFFFFF)
///    - #RRGGBBAA (8个字符，带透明度，如 #FFFFFFFF)
/// 4. 可选择是否转换为大写
/// 5. 可设置最大长度（默认9，包含#）
/// 6. 当输入第7个字符时，保存完整值并用 '#' 替代显示
class ColorValueFormatter extends TextInputFormatter {
  final int maxLength; // 最大长度（包含#），默认9 (#RRGGBBAA)
  final bool toUpperCase; // 是否转换为大写
  final int minLength; // 最小长度（包含#），默认2 (#)

  // 全局变量：保存完整的7个字符的值
  static String? _savedFullValue;

  // 回调函数：当保存完整值时调用
  static Function(String)? onValueSaved;

  /// 获取保存的完整值
  static String? get savedFullValue => _savedFullValue;

  /// 设置值保存回调
  static void setOnValueSavedCallback(Function(String)? callback) {
    onValueSaved = callback;
  }

  /// 清除保存的值
  static void clearSavedValue() {
    _savedFullValue = null;
  }

  const ColorValueFormatter({
    this.maxLength = 7, // # + 6位
    this.toUpperCase = true,
    this.minLength = 2, // # + 至少1位 = 2
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    final oldLength = oldText.length;
    final newLength = newText.length;

    // 情况1：空值处理 - 自动添加 #
    if (newText.isEmpty) {
      _savedFullValue = null;
      return TextEditingValue(
        text: '#',
        selection: const TextSelection.collapsed(offset: 1),
        composing: TextRange.empty,
      );
    }

    // 情况2：如果当前显示的是 "#"（占位符状态）
    if (newText == '#') {
      return TextEditingValue(
        text: '#',
        selection: const TextSelection.collapsed(offset: 1),
        composing: TextRange.empty,
      );
    }

    // 情况3：如果第一个字符不是 #，自动添加
    if (!newText.startsWith('#')) {
      // 过滤出有效的十六进制字符
      final hexChars = newText.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (hexChars.isEmpty) {
        return TextEditingValue(
          text: '#',
          selection: const TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        );
      }

      // 限制长度并添加 #
      final limited = hexChars.length > (maxLength - 1)
          ? hexChars.substring(0, maxLength - 1)
          : hexChars;
      final formatted = toUpperCase ? '#${limited.toUpperCase()}' : '#$limited';

      // 检测是否达到第7个字符
      if (formatted.length == 7) {
        _savedFullValue = formatted;
        onValueSaved?.call(formatted);
        // 用 "#" 替代显示
        return TextEditingValue(
          text: '#',
          selection: const TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        );
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
        composing: TextRange.empty,
      );
    }

    // 情况4：确保 # 不能被删除（至少保留 #）
    if (newLength == 1 && newText == '#') {
      return TextEditingValue(
        text: '#',
        selection: const TextSelection.collapsed(offset: 1),
        composing: TextRange.empty,
      );
    }

    // 情况5：如果尝试删除 #，阻止删除
    if (oldText.startsWith('#') && !newText.startsWith('#')) {
      // 恢复为至少有 # 的格式
      final hexChars = newText.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (hexChars.isEmpty) {
        return TextEditingValue(
          text: '#',
          selection: const TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        );
      }

      final limited = hexChars.length > (maxLength - 1)
          ? hexChars.substring(0, maxLength - 1)
          : hexChars;
      final formatted = toUpperCase ? '#${limited.toUpperCase()}' : '#$limited';

      // 如果删除导致少于7个字符，清除保存的值
      if (oldLength == 7 && formatted.length < 7) {
        _savedFullValue = null;
      }

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
        composing: TextRange.empty,
      );
    }

    // 情况6：提取 # 后的字符，只保留有效的十六进制字符
    final afterHash = newText.substring(1);
    final hexChars = afterHash.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');

    // 限制长度
    final limited = hexChars.length > (maxLength - 1)
        ? hexChars.substring(0, maxLength - 1)
        : hexChars;

    // 转换为大写（如果需要）
    final formatted = toUpperCase ? '#${limited.toUpperCase()}' : '#$limited';

    // 检测是否输入了第7个字符（从6个变成7个）
    if (oldLength == 7 && formatted.length == 8) {
      // 保存完整的7个字符值到全局变量
      _savedFullValue = formatted;
      // 触发回调
      onValueSaved?.call(formatted);
      // 用 "#" 替代显示
      return TextEditingValue(
        text: '#',
        selection: const TextSelection.collapsed(offset: 1),
        composing: TextRange.empty,
      );
    }

    // 情况8：如果超过7个字符，截取前7个，然后保存并显示 #
    if (formatted.length > 7) {
      final truncated7 = formatted.substring(0, 7);
      // 如果旧值长度小于7，说明是新输入导致的
      if (oldLength < 7) {
        _savedFullValue = truncated7;
        onValueSaved?.call(truncated7);
        return TextEditingValue(
          text: '#',
          selection: const TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        );
      }
    }

    // 情况9：如果删除导致少于7个字符，清除保存的值
    if (oldLength == 7 && formatted.length < 7) {
      _savedFullValue = null;
    }

    // 计算光标位置
    int cursorOffset = newValue.selection.baseOffset;

    // 如果删除了字符，需要调整光标位置
    if (newLength < oldLength) {
      // 删除操作：光标保持在合理位置
      cursorOffset = formatted.length;
    } else {
      // 输入操作：根据过滤后的文本调整光标
      cursorOffset = formatted.length;
    }

    // 确保光标位置有效
    cursorOffset = cursorOffset.clamp(1, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
      composing: TextRange.empty,
    );
  }
}
