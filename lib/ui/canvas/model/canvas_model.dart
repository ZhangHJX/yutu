import 'package:flutter/material.dart';
import 'canvas_element.dart';

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
  void updateMatrix4(Matrix4 matrix, double scale, Offset offset) {
    transform = matrix.clone();
    // this.offset = offset;
    // this.scale = scale;
  }
}
