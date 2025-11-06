import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

enum ElementType { canvals, image, rectangle, ellipse, line, text }

class DesignCanvalsModel {
  final String id;
  final double width;
  final double height;
  final double canvasRatio;
  final List<EditBoxData>? editBoxData;

  DesignCanvalsModel({
    required this.canvasRatio,
    this.editBoxData,
    required this.id,
    required this.width,
    required this.height,
  });
}

// 所有的模型数据
@JsonSerializable(explicitToJson: true)
class EditBoxData {
  final String id;
  final ElementType type;

  // 画布属性
  double width;
  double height;
  String canvalsFillColor;
  double canvalsFillAlpha;
  String canvalsBorderColor;
  double canvalsBorderWidth;
  double canvalsBorderAlpha;

  Offset position;
  String text;

  // 图片相关属性
  String imagePath;

  // 形状/文字相关属性
  String fillColor;
  double fillAlpha;
  String borderColor;
  double borderWidth;
  double borderAlpha;

  String fontFamily; // 字体
  double fontSize; // 字体大小
  FontWeight fontWeight; // 字重
  String textColor; // 字体颜色
  double lineHeight; // 行高/行间距（相对于fontSize的倍数）
  double fontSpace; // 字间距
  TextAlign align;
  double textAlpha;

  // 阴影相关
  bool isShawOpen;
  String shawColor;
  double shawX;
  double shawY;
  double blurValue;
  double shawAlpha;

  // Pointer 相关属性
  double rotation; // 旋转角度
  double cumulativeScale; // 累积缩放比例
  Offset? fixedScaleCenter; // 固定的缩放中心点
  double initialWidth; // 初始宽度（用于缩放计算）
  double initialHeight; // 初始高度（用于缩放计算）
  double initialFontSize; // 初始字体大小（用于缩放计算）

  // 调整大小相关属性
  String? resizingHandle; // 当前正在调整的控制点位置
  double resizeStartWidth; // 调整大小开始时的宽度
  double resizeStartHeight; // 调整大小开始时的高度
  double resizeStartFontSize; // 调整大小开始时的字体大小
  double resizeStartLineHeight; // 调整大小开始时的行高
  double resizeStartFontSpace; // 调整大小开始时的字间距
  double resizeAspectRatio; // 调整大小开始时的宽高比
  Offset? resizeStartPosition; // 调整大小开始时的触摸位置
  Offset? resizeAnchorPoint; // 调整大小时的锚点（对角点）

  // 旋转相关属性
  Offset? rotateLastPosition; // 旋转时的上一次触摸位置

  // 图层相关属性
  bool visible; // 元素是否可见
  bool isLock; // 元素是否被锁

  EditBoxData({
    required this.id,
    required this.type,

    // 画布相关属性
    required this.width,
    required this.height,
    this.canvalsFillColor = '#D8D8D8',
    this.canvalsFillAlpha = 1.0,
    this.canvalsBorderColor = '#BFBFBF',
    this.canvalsBorderWidth = 1.0,
    this.canvalsBorderAlpha = 1.0,

    required this.position,

    // 可见性属性的默认值
    this.visible = true,
    this.isLock = false,

    this.imagePath = '',
    this.text = '',
    this.fillAlpha = 1.0,
    this.fillColor = '#D8D8D8',

    this.borderColor = '#D8D8D8',

    this.borderWidth = 0,
    this.borderAlpha = 1.0,

    this.fontFamily = "Courier",
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.textColor = "#000000",
    this.lineHeight = 1.0,
    this.fontSpace = 0,
    this.align = TextAlign.center,
    this.textAlpha = 1.0,

    this.shawColor = '#D8D8D8',
    this.shawX = 0,
    this.shawY = 0,
    this.blurValue = 0,
    this.isShawOpen = false,
    this.shawAlpha = 1.0,

    // Pointer 相关属性的默认值
    this.rotation = 0.0,
    this.cumulativeScale = 1.0,
    this.fixedScaleCenter,
    double? initialWidth,
    double? initialHeight,

    // 调整大小相关属性的默认值
    this.resizingHandle,
    this.resizeStartWidth = 300.0,
    this.resizeStartHeight = 200.0,
    this.resizeStartFontSize = 14.0,
    double? resizeStartLineHeight,
    double? resizeStartFontSpace,
    double? resizeAspectRatio,
    this.resizeStartPosition,
    this.resizeAnchorPoint,

    // 旋转相关属性的默认值
    this.rotateLastPosition,
  }) : initialWidth = initialWidth ?? width,
       initialHeight = initialHeight ?? height,
       initialFontSize = fontSize,
       resizeStartLineHeight = resizeStartLineHeight ?? lineHeight,
       resizeStartFontSpace = resizeStartFontSpace ?? fontSpace,
       resizeAspectRatio = resizeAspectRatio ?? (width / height);
}
