import 'package:flutter/material.dart';
import 'canvas_element.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class CanvasModel {
  double width;
  double height;

  String fillColor;
  double fillAlpha;
  String borderColor;
  double borderWidth;
  double borderAlpha;
  bool locked;
  bool isSelected;

  Matrix4 transform = Matrix4.identity();
  double scale = 1.0;
  List<CanvasElement> elements = [];

  void addElement(CanvasElement e) => elements.add(e);

  CanvasModel({
    this.width = 1200,
    this.height = 1600,
    this.fillColor = '#FFFFFF',
    this.fillAlpha = 1.0,
    this.borderColor = '#BFBFBF',
    this.borderWidth = 0.0,
    this.borderAlpha = 1.0,
    this.locked = true,
    this.isSelected = false,
  });
}

/// CanvasModel 相关变换扩展（统一构建画布矩阵）
extension CanvasModelViewportTransformX on CanvasModel {
  /// 根据视口偏移和缩放更新画布变换
  void applyViewportTransform(Offset offset, double scale) {
    transform = Matrix4.identity()
      ..translateByVector3(Vector3(offset.dx, offset.dy, 0))
      ..scaleByVector3(Vector3(scale, scale, 1));
    this.scale = scale;
  }
}
