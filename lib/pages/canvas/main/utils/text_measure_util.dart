import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 与画布内 [Text] 一致：避免 `TextStyle.height` 挤压首尾行导致字形在固定高度内被裁切。
const TextHeightBehavior kCanvasTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

class TextMeasureUtil {
  /// 智能计算文本尺寸：自动判断单行/多行并返回实际的宽高
  /// [text] 要测量的文本
  /// [fontSize] 字体大小
  /// [fontFamily] 字体
  /// [letterSpacing] 字间距（字符之间的间距）
  /// [lineHeight] 行高（相对于字体大小的倍数，如 1.5 表示 1.5 倍行高）
  static Size measureText({
    required String text,
    double? fontSize = defaultConfigFontSize,
    String? fontFamily = defaultConfigFamliy,
    double? letterSpacing = 0,
    double? lineHeight = kCanvasDefaultTextLineHeight,
  }) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily, // ✅ 使用 familyKey（postScriptName）精确匹配字体文件
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    return _measureWithStyle(text: text, textStyle: textStyle);
  }

  /// 根据固定宽度计算文本尺寸
  /// [text] 要测量的文本
  /// [fontSize] 字体大小
  /// [fontFamily] 字体
  /// [letterSpacing] 字间距
  /// [lineHeight] 行高（相对于字体大小的倍数）
  /// [maxWidth] 最大宽度限制
  static Size measureTextWithWidth({
    required String text,
    required double fontSize,
    required String? fontFamily,
    required double? letterSpacing,
    required double? lineHeight,
    required double maxWidth,
  }) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily, // ✅ 使用 familyKey（postScriptName）精确匹配字体文件
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      textHeightBehavior: kCanvasTextHeightBehavior,
    );

    // 减去padding后的可用宽度
    final availableWidth = maxWidth;
    textPainter.layout(maxWidth: availableWidth);

    // 返回尺寸
    // 对于单行文本，去除尾随空白后重新测量以获得精确宽度
    final trimmedText = text.trimRight();
    if (trimmedText != text && !text.contains('\n')) {
      // 如果是单行且有尾随空白，使用去除空白后的文本重新测量
      final trimmedPainter = TextPainter(
        text: TextSpan(text: trimmedText, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textHeightBehavior: kCanvasTextHeightBehavior,
      );
      trimmedPainter.layout(maxWidth: availableWidth);
      return Size(trimmedPainter.width, textPainter.height);
    }

    return Size(textPainter.width, textPainter.height);
  }

  /// 内部测量方法
  static Size _measureWithStyle({
    required String text,
    required TextStyle textStyle,
  }) {
    // 去除文本末尾的空白字符，避免测量时包含尾随空白
    final trimmedText = text.trimRight();

    // 检查文本是否包含换行符
    final hasLineBreaks = trimmedText.contains('\n');

    final textPainter = TextPainter(
      text: TextSpan(text: trimmedText, style: textStyle),
      textDirection: TextDirection.ltr,
      textHeightBehavior: kCanvasTextHeightBehavior,
    );

    if (hasLineBreaks) {
      // 多行文本或有宽度限制
      textPainter.layout(maxWidth: double.infinity);
    } else {
      // 单行文本，无宽度限制
      textPainter.layout();
    }

    // 对于单行文本，textPainter.width 应该已经是精确的（因为我们已经去除了尾随空白）
    // 如果文本为空，返回最小尺寸
    final width = trimmedText.isEmpty ? 0.0 : textPainter.width;

    return Size(width, textPainter.height);
  }
}
