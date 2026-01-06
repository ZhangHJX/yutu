import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:common/common.dart';
import 'canvas_element.dart';
import 'dart:math' as math;

// import 'package:objectbox/objectbox.dart';

part 'canvas_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CanvasModel {
  int id;
  String uuid;
  String ratio;
  String clarity;
  bool isCreate;

  double x;
  double y;
  double scale;
  double width;
  double height;
  String fillColor;
  double fillAlpha;
  bool locked;
  bool isSelected;

  /// 版本号
  double version;

  ///时间戳
  int timestamp;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Matrix4 transform = Matrix4.identity();

  List<CanvasElement> elements;

  CanvasModel({
    this.id = 0,
    this.uuid = '',
    this.ratio = '',
    this.clarity = '0',
    this.isCreate = false,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 1080,
    this.height = 1080,
    this.scale = 1.0,
    this.fillColor = '#FFFFFF',
    this.fillAlpha = 1.0,
    this.locked = false,
    this.isSelected = false,
    this.elements = const [],
    this.version = 1.0,
    this.timestamp = 0,
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
