
import 'package:common/common.dart';
import 'package:flutter/material.dart';

// 创建一个自定义文本绘制 widget
class CustomTextWithBorder extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Color borderColor;
  final double borderWidth;
  final Color? fillColor;
  final TextAlign textAlign;

  const CustomTextWithBorder({super.key,
    required this.text,
    required this.baseStyle,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.fillColor,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TextWithBorderPainter(
        text: text,
        textStyle: baseStyle,
        borderColor: borderColor,
        borderWidth: borderWidth,
        fillColor: fillColor,
        textAlign: textAlign,
      ),
      size: Size.infinite,
    );
  }
}

class TextWithBorderPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final Color borderColor;
  final double borderWidth;
  final Color? fillColor;
  final TextAlign textAlign;

  TextWithBorderPainter({
    required this.text,
    required this.textStyle,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.fillColor,
    this.textAlign = TextAlign.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    textPainter.layout(maxWidth: size.width);

    // 绘制描边
    if (borderWidth > 0) {
      final borderPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderWidth
              ..color = borderColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
      );
      borderPainter.layout(maxWidth: size.width);

      final offset = _getOffsetForAlign(size, borderPainter);
      borderPainter.paint(canvas, offset);
    }

    // 绘制填充背景（如果设置了 fillColor）
    if (fillColor != null) {
      final fillPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(
            backgroundColor: fillColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
      );
      fillPainter.layout(maxWidth: size.width);

      final offset = _getOffsetForAlign(size, fillPainter);
      fillPainter.paint(canvas, offset);
    }

    // 绘制文本主体
    final offset = _getOffsetForAlign(size, textPainter);
    textPainter.paint(canvas, offset);
  }

  Offset _getOffsetForAlign(Size size, TextPainter painter) {
    switch (textAlign) {
      case TextAlign.center:
        return Offset((size.width - painter.width) / 2, 0);
      case TextAlign.right:
        return Offset(size.width - painter.width, 0);
      case TextAlign.justify:
      case TextAlign.start:
      case TextAlign.end:
      case TextAlign.left:
      default:
        return Offset.zero;
    }
  }

  @override
  bool shouldRepaint(TextWithBorderPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.fillColor != fillColor;
  }
}