import 'package:flutter/material.dart';
import 'canvas_element.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class CanvasModel {
  Matrix4 transform = Matrix4.identity();
  double scale = 1.0;
  Offset offset = Offset.zero;
  List<CanvasElement> elements = [];

  double width;
  double height;

  String fillColor;
  double fillAlpha;
  String borderColor;
  double borderWidth;
  double borderAlpha;
  bool locked;
  bool isSelected;

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

  /// 根据视口偏移和缩放更新画布变换
  /// 注意：这里是“设值”，不是在原有矩阵上叠加，否则每一帧都会累乘，导致拖动/缩放越来越失控。
  void updateMatrix4(Offset offset, double scale) {
    transform = Matrix4.identity()
      ..translateByVector3(Vector3(offset.dx, offset.dy, 0))
      ..scaleByVector3(Vector3(scale, scale, 1));

    this.offset = offset;
    this.scale = scale;
  }

  /// 画布尺寸转换工具类
  Size getCanvalsSize(double availableWidth, double availableHeight) {
    // 计算画布宽高比
    final canvasRatio = width / height;
    final availableRatio = availableWidth / availableHeight;

    double displayWidth;
    double displayHeight;

    if (canvasRatio > availableRatio) {
      // 画布更宽，以宽度为基准充满
      displayWidth = availableWidth;
      displayHeight = availableWidth / canvasRatio;
    } else {
      // 画布更高，以高度为基准充满
      displayHeight = availableHeight;
      displayWidth = availableHeight * (width / height);
    }

    return Size(displayWidth, displayHeight);
  }
}
