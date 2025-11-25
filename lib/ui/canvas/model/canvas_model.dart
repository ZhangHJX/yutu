import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

part 'canvas_model.g.dart';

@JsonSerializable()
class CanvasModel {
  String id;
  double x;
  double y;
  double scale;

  @JsonKey(defaultValue: 1080)
  double width;
  @JsonKey(defaultValue: 1080)
  double height;

  String fillColor;
  double fillAlpha;
  String borderColor;
  double borderWidth;
  double borderAlpha;
  bool locked;
  bool isSelected;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Matrix4 transform = Matrix4.identity();

  CanvasModel({
    required this.id,
    required this.width,
    required this.height,
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.fillColor = '#FFFFFF',
    this.fillAlpha = 1.0,
    this.borderColor = '#BFBFBF',
    this.borderWidth = 1.0,
    this.borderAlpha = 1.0,
    this.locked = false,
    this.isSelected = false,
  });

  // 自动生成的 JSON 解析
  factory CanvasModel.fromJson(Map<String, dynamic> json) =>
      _$CanvasModelFromJson(json);

  /// 自动生成的 JSON 输出
  Map<String, dynamic> toJson() => _$CanvasModelToJson(this);

  /// 根据视口偏移和缩放更新画布变换；注意：这里是“设值”，不是在原有矩阵上叠加，否则每一帧都会累乘，导致拖动/缩放越来越失控
  void updateMatrix4(Matrix4 matrix, double scale, Offset offset) {
    transform = matrix;
    x = offset.dx;
    y = offset.dy;
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

    x = offsetX;
    y = offsetY;

    transform = Matrix4.identity()
      ..scaleByVector3(Vector3(scale, scale, 1))
      ..translateByVector3(Vector3(offsetX, offsetY, 0));
  }
}
