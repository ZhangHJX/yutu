import 'package:common/src/entry.dart';
import 'package:flutter/material.dart';

/// 数字徽标
class CBadgeNumber extends StatelessWidget {
  const CBadgeNumber({
    required this.lowPadding,
    required this.color,
    required this.backgroundColor,
    required this.fontSize,
    required this.borderRadius,
    required this.height,
    super.key,
    this.count,
    this.countText,
    this.highPadding,
    this.border,
  }) : assert((count == null) ^ (countText == null), 'count 和 countText 必须且只能有一个有值');

  final int? count;
  final String? countText;
  final double fontSize;

  /// 个位数时候的padding
  final EdgeInsets lowPadding;

  /// 两位数+时候的padding
  final EdgeInsets? highPadding;

  final double height;

  final Border? border;
  final Color color;
  final Color backgroundColor;
  final double borderRadius;

  String get displayText {
    if (count != null) {
      return count! > 99 ? '99+' : count!.toString();
    }
    return countText!;
  }

  bool get isSingleDigit => displayText.length == 1;

  @override
  Widget build(BuildContext context) {
    final padding = isSingleDigit ? lowPadding : highPadding ?? lowPadding;
    return Container(
      alignment: Alignment.center,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: fontSize.w,
          height: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
