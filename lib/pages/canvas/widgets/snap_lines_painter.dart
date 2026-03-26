import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../gesture/element_snap_helper.dart';

/// 吸附参考线绘制器
///
/// [SnapLine] 中的数值与 [CanvasElement] 模型一致（设计稿坐标系）。
/// 元素实际通过 [CanvasElement.updateMatrix4] 使用 [.w] 映射到布局坐标，
/// 故绘制参考线时也必须做相同缩放，否则会与元素边缘错位（常见为整体偏上）。
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
        final x = line.position.w;
        // 绘制垂直线
        canvas.drawLine(Offset(x, line.start.w), Offset(x, line.end.w), paint);
      } else {
        // 绘制水平线
        final y = line.position.w;
        canvas.drawLine(Offset(line.start.w, y), Offset(line.end.w, y), paint);
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
