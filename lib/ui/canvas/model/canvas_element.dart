import 'package:flutter/material.dart';

enum ElementType { image, rectangle, ellipse, line, text }

class CanvasElement {
  String id;
  ElementType type;
  Matrix4 transform;
  Offset position;
  double width;
  double height;

  bool hidden; // 元素是否可见
  bool locked; // 元素是否被锁
  bool selected; // 是否被选中

  // 图片相关属性
  String imagePath;
  double imageAlpha;

  // 形状相关属性
  String fillColor;
  double fillAlpha;

  // 文字相关属性
  String text;
  String fontFamily;
  double fontSize;
  FontWeight fontWeight;
  double lineHeight;
  double fontSpace;
  TextAlign align;
  String textColor;
  double textAlpha;

  // 公共属性--阴影相关
  bool isShawOpen;
  String shawColor;
  double shawX;
  double shawY;
  double blurValue;
  double shawAlpha;

  // 公共属性--边框相关
  String borderColor;
  double borderWidth;
  double borderAlpha;

  /// local rect centered at origin
  Rect get localRect =>
      Rect.fromCenter(center: Offset.zero, width: width, height: height);

  /// local corners around origin (center-based)
  List<Offset> get localCorners => [
    Offset(-width / 2, -height / 2),
    Offset(width / 2, -height / 2),
    Offset(width / 2, height / 2),
    Offset(-width / 2, height / 2),
  ];

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

  CanvasElement({
    this.id = '',
    required this.type,
    required this.position,
    required this.width,
    required this.height,

    this.imagePath = '',
    this.imageAlpha = 1.0,

    this.fillAlpha = 1.0,
    this.fillColor = '#D8D8D8',

    this.text = '',
    this.fontFamily = "Courier",
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.lineHeight = 1.0,
    this.fontSpace = 0,
    this.align = TextAlign.center,
    this.textColor = "#000000",
    this.textAlpha = 1.0,

    this.isShawOpen = false,
    this.shawColor = '#D8D8D8',
    this.shawX = 0,
    this.shawY = 0,
    this.blurValue = 0,
    this.shawAlpha = 1.0,

    this.borderColor = '#D8D8D8',
    this.borderWidth = 0,
    this.borderAlpha = 1.0,

    // 可见性属性的默认值
    this.hidden = false,
    this.locked = false,
    this.selected = false,
    Matrix4? transform,

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
  }) : transform = transform ?? Matrix4.identity(),
       initialWidth = initialWidth ?? width,
       initialHeight = initialHeight ?? height,
       initialFontSize = fontSize,
       resizeStartLineHeight = resizeStartLineHeight ?? lineHeight,
       resizeStartFontSpace = resizeStartFontSpace ?? fontSpace,
       resizeAspectRatio = resizeAspectRatio ?? (width / height);
}
