import 'package:flutter/material.dart';

import 'c_gradient_border_painter.dart';
import 'c_gradient_text.dart' show defaultGradientColors;

/// 渐变色边框
class CGradientBorderWidget extends StatelessWidget {
  const CGradientBorderWidget({
    required this.borderRadius,
    required this.child,
    this.gradientColors = defaultGradientColors,
    this.borderWidth = 1,
    this.begin = const Alignment(-0.3, -1),
    this.end = const Alignment(1, 0.3),
    this.padding,
    this.margin,
    this.width,
    this.height,
    super.key,
  });

  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<Color> gradientColors;
  final Alignment begin;
  final Alignment end;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final paintChild = CustomPaint(
      foregroundPainter: CGradientBorderPainter(
        gradient: LinearGradient(colors: gradientColors, begin: begin, end: end),
        borderRadius: borderRadius.topLeft.x,
        strokeWidth: borderWidth,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(width: width, height: height, padding: padding, child: child),
      ),
    );
    return margin == null ? paintChild : Padding(padding: margin!, child: paintChild);
  }
}
