import 'package:flutter/material.dart';

class StrokeText extends StatelessWidget {
  final String text;
  final double strokeWidth;
  final Color strokeColor;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final int? maxLines;

  const StrokeText({
    super.key,
    required this.text,
    this.strokeWidth = 0,
    required this.strokeColor,
    required this.textStyle,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildText({Paint? foreground}) {
      return Text(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        softWrap: true,
        style: foreground != null
            ? textStyle.copyWith(foreground: foreground, color: null)
            : textStyle,
      );
    }

    // 无描边：正常文字（带阴影，宽度遵循父级约束，可以自动换行）
    if (strokeWidth == 0) {
      return buildText();
    }

    // 有描边时：先画描边文字，再在上面画正常填充文字
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor;

    // 使用 Stack 而不是 OverflowBox，让宽度遵循父级约束，从而在宽度不够时可以自动换行；
    // 同时通过 clipBehavior: Clip.none 让文字可以在父容器范围外继续显示。
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 外描边
        buildText(foreground: strokePaint),
        // 填充文字
        buildText(),
      ],
    );
  }
}
