import 'package:flutter/material.dart';

class TextMeasureUtil {
  /// 智能计算文本尺寸：自动判断单行/多行并返回实际的宽高
  /// [text] 要测量的文本
  /// [fontSize] 字体大小
  /// [fontFamily] 字体
  /// [fontWeight] 字重
  /// [letterSpacing] 字间距（字符之间的间距）
  /// [lineHeight] 行高（相对于字体大小的倍数，如 1.5 表示 1.5 倍行高）
  static Size measureText({
    required String text,
    required double fontSize,
    required String? fontFamily,
    required FontWeight? fontWeight,
    required double? letterSpacing,
    required double? lineHeight,
  }) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    return _measureWithStyle(text: text, textStyle: textStyle);
  }

  /// 根据固定宽度计算文本尺寸（包含padding）
  /// [text] 要测量的文本
  /// [fontSize] 字体大小
  /// [fontFamily] 字体
  /// [fontWeight] 字重
  /// [letterSpacing] 字间距
  /// [lineHeight] 行高（相对于字体大小的倍数）
  /// [maxWidth] 最大宽度限制
  static Size measureTextWithWidth({
    required String text,
    required double fontSize,
    required String? fontFamily,
    required FontWeight? fontWeight,
    required double? letterSpacing,
    required double? lineHeight,
    required double maxWidth,
  }) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 减去padding后的可用宽度
    final availableWidth = maxWidth;
    textPainter.layout(maxWidth: availableWidth);

    // 返回尺寸时加上padding
    return Size(textPainter.width, textPainter.height);
  }

  /// 内部测量方法
  static Size _measureWithStyle({
    required String text,
    required TextStyle textStyle,
  }) {
    // 检查文本是否包含换行符
    final hasLineBreaks = text.contains('\n');

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    if (hasLineBreaks) {
      // 多行文本或有宽度限制
      textPainter.layout(maxWidth: double.infinity);
    } else {
      // 单行文本，无宽度限制
      textPainter.layout();
    }

    return Size(textPainter.width, textPainter.height);
  }
}
