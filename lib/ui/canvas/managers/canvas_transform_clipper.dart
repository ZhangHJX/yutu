import 'package:flutter/material.dart';

class CanvasTransformClipper extends CustomClipper<Path> {
  final Matrix4 matrix;
  final Size canvasSize; // 画布本身未变换的逻辑尺寸

  CanvasTransformClipper({required this.matrix, required this.canvasSize});

  @override
  Path getClip(Size size) {
    // 画布的四个顶点 (逻辑坐标)
    final List<Offset> logicalCorners = [
      Offset.zero,
      Offset(canvasSize.width, 0),
      Offset(canvasSize.width, canvasSize.height),
      Offset(0, canvasSize.height),
    ];

    // 转换为屏幕坐标
    final List<Offset> transformed = logicalCorners
        .map((p) => MatrixUtils.transformPoint(matrix, p))
        .toList();

    // 计算包围盒
    double minX = transformed.first.dx;
    double minY = transformed.first.dy;
    double maxX = transformed.first.dx;
    double maxY = transformed.first.dy;

    for (final p in transformed) {
      minX = minX < p.dx ? minX : p.dx;
      minY = minY < p.dy ? minY : p.dy;
      maxX = maxX > p.dx ? maxX : p.dx;
      maxY = maxY > p.dy ? maxY : p.dy;
    }

    // 裁剪区域（屏幕坐标下）
    final Rect clipRect = Rect.fromLTRB(minX, minY, maxX, maxY);

    return Path()..addRect(clipRect);
  }

  @override
  bool shouldReclip(CanvasTransformClipper oldClipper) {
    return oldClipper.matrix != matrix || oldClipper.canvasSize != canvasSize;
  }
}
