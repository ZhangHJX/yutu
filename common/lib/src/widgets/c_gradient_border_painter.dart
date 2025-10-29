import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 渐变边框绘制器
class CGradientBorderPainter extends CustomPainter {
  CGradientBorderPainter({required this.gradient, required this.borderRadius, double? strokeWidth})
    : strokeWidth = strokeWidth ?? hairline;

  final Gradient gradient;
  final double borderRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CGradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
