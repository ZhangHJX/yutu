import 'package:flutter/material.dart';
import '../gesture/element_snap_helper.dart';

/// 吸附参考线绘制器
class SnapLinesPainter extends CustomPainter {
  final List<SnapLine> snapLines;

  SnapLinesPainter({required this.snapLines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors
          .red // 粉红色参考线
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final line in snapLines) {
      if (line.isVertical) {
        // 绘制垂直线
        canvas.drawLine(
          Offset(line.position, line.start),
          Offset(line.position, line.end),
          paint,
        );
      } else {
        // 绘制水平线
        canvas.drawLine(
          Offset(line.start, line.position),
          Offset(line.end, line.position),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SnapLinesPainter oldDelegate) {
    if (snapLines.length != oldDelegate.snapLines.length) {
      return true;
    }
    for (int i = 0; i < snapLines.length; i++) {
      final oldLine = oldDelegate.snapLines[i];
      final newLine = snapLines[i];
      if (oldLine.isVertical != newLine.isVertical ||
          oldLine.position != newLine.position ||
          oldLine.start != newLine.start ||
          oldLine.end != newLine.end) {
        return true;
      }
    }
    return false;
  }
}
