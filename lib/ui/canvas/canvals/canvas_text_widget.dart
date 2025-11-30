import 'package:flutter/material.dart';

class CanvasTextWidget extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final TextAlign textAlign;
  final int? maxLines;

  const CanvasTextWidget({
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
    // 如果没有描边，直接用普通 Text，省一次绘制
    final hasStroke = strokeWidth > 0 && strokeColor.a > 0;

    if (!hasStroke) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Text(
              text,
              textAlign: textAlign,
              maxLines: maxLines,
              softWrap: true,
              overflow: TextOverflow.clip,
              style: textStyle.copyWith(color: fillColor),
            ),
          );
        },
      );
    }

    // 有描边：用双层 Text 叠加
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillStyle = textStyle.copyWith(
          color: fillColor,
          // 填充层保留阴影等效果
        );

        final strokeStyle = textStyle.copyWith(
          // stroke 层用 foreground 画描边
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..color = strokeColor,
          // 一般描边层不需要阴影，防止边缘虚掉
          shadows: const [],
          color: null, // 用 foreground，不要再用 color
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              // 底层：描边
              SizedBox(
                width: constraints.maxWidth,
                child: Text(
                  text,
                  textAlign: textAlign,
                  maxLines: maxLines,
                  softWrap: true,
                  overflow: TextOverflow.clip,
                  style: strokeStyle,
                ),
              ),
              // 上层：填充
              SizedBox(
                width: constraints.maxWidth,
                child: Text(
                  text,
                  textAlign: textAlign,
                  maxLines: maxLines,
                  softWrap: true,
                  overflow: TextOverflow.clip,
                  style: fillStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
