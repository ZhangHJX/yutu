import 'package:flutter/material.dart';

class CDashedLine extends StatelessWidget {
  const CDashedLine({
    required this.height,
    required this.width,
    required this.axis,
    super.key,
    this.dashHeight = 2,
    this.dashWidth = 2,
    this.dashSpace = 2,
    this.strokeWidth = 1,
    this.dashColor = const Color(0xFFEAEAEA),
  });

  /// 虚线的高度
  final double height;

  /// 虚线的宽度
  final double width;

  /// 轴线方向
  final Axis axis;

  /// 虚线高度, 默认为2, 当轴线方向为垂直时有效
  final double dashHeight;

  /// 虚线宽度, 默认为2, 当轴线方向为水平时有效
  final double dashWidth;

  /// 虚线间距, 默认为2
  final double dashSpace;

  /// 虚线粗细, 默认为1
  final double strokeWidth;

  /// 虚线颜色
  final Color dashColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _DashedLinePainter(
        axis: axis,
        dashHeight: dashHeight,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        dashColor: dashColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.axis,
    required this.dashHeight,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
    required this.dashColor,
  });
  final Axis axis;
  final double dashHeight;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final Color dashColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (axis == Axis.vertical) {
      double startY = 0;
      final paint = Paint()
        ..color = dashColor
        ..strokeWidth = strokeWidth;
      while (startY < size.height) {
        canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
        startY += dashHeight + dashSpace;
      }
    } else {
      double startX = 0;
      final paint = Paint()
        ..color = dashColor
        ..strokeWidth = strokeWidth;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
