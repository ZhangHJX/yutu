import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'canvas_element.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

class CanvasModel {
  double scale;
  Offset offset = Offset.zero;
  Matrix4 transform = Matrix4.identity();
  double width;
  double height;

  String fillColor;
  double fillAlpha;
  String borderColor;
  double borderWidth;
  double borderAlpha;
  bool locked;
  bool isSelected;

  List<CanvasElement> elements = [];

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
    this.scale = 1.0,
  });

  /// 根据视口偏移和缩放更新画布变换
  /// 注意：这里是“设值”，不是在原有矩阵上叠加，否则每一帧都会累乘，导致拖动/缩放越来越失控。
  void updateMatrix4(Matrix4 matrix, double scale, Offset offset) {
    transform = matrix;
    this.offset = offset;
    this.scale = scale;
  }

  /// 画布尺寸转换工具类
  Size getCanvalsSize(double availableWidth, double availableHeight) {
    final scaleW = availableWidth / width;
    final scaleH = availableHeight / height;
    final double minScale = math.min(scaleW, scaleH);
    return Size(width * minScale, height * minScale);
  }

  void getMatrix4() {
    final containerHeight =
        ScreenTools.screenHeight -
        ScreenTools.statusBarHeight -
        ScreenTools.bottomBarHeight -
        117.w;
    final containerWidth = ScreenTools.screenWidth;
    final scaleW = containerWidth / width;
    final scaleH = containerHeight / height;
    final double minScale = math.min(scaleW, scaleH);

    final double displayWidth = width * minScale;
    final double displayHeight = height * minScale;
    final double offsetX = (containerWidth - displayWidth) / 2.0;
    final double offsetY = (containerHeight - displayHeight) / 2.0;

    offset = Offset(offsetX, offsetY);

    transform = Matrix4.identity()
      ..scaleByVector3(Vector3(scale, scale, 1))
      ..translateByVector3(Vector3(offsetX, offsetY, 0));
  }
}
