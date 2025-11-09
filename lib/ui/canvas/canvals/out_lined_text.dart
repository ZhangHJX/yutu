import 'package:flutter/material.dart';

class OutlinedTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final TextAlign textAlign;
  final int? maxLines;

  OutlinedTextPainter({
    required this.text,
    required this.textStyle,
    required this.strokeWidth,
    required this.strokeColor,
    required this.fillColor,
    required this.textAlign,
    this.maxLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: textAlign,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);

    // 绘制描边
    final strokePainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..color = strokeColor,
        ),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    strokePainter.layout(maxWidth: size.width);

    // 先画描边，再画填充
    strokePainter.paint(canvas, Offset.zero);
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(OutlinedTextPainter oldDelegate) {
    return text != oldDelegate.text ||
        textStyle != oldDelegate.textStyle ||
        strokeWidth != oldDelegate.strokeWidth ||
        strokeColor != oldDelegate.strokeColor ||
        fillColor != oldDelegate.fillColor ||
        textAlign != oldDelegate.textAlign ||
        maxLines != oldDelegate.maxLines;
  }
}

// 使用组件
class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final TextAlign textAlign;
  final int? maxLines;

  const OutlinedText({
    super.key,
    required this.text,
    required this.textStyle,
    required this.strokeWidth,
    required this.strokeColor,
    required this.fillColor,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: textStyle.copyWith(color: fillColor),
          ),
          maxLines: maxLines,
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        return CustomPaint(
          size: textPainter.size,
          painter: OutlinedTextPainter(
            text: text,
            textStyle: textStyle.copyWith(color: fillColor),
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            fillColor: fillColor,
            textAlign: textAlign,
            maxLines: maxLines,
          ),
        );
      },
    );
  }
}
