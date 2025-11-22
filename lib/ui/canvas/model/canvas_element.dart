import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

enum ElementType { image, rectangle, ellipse, line, text }

class CanvasElement {
  String id;
  ElementType type;
  Matrix4 transform;
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
  int borderWidth;
  double borderAlpha;

  // Pointer 相关属性
  Offset position;
  double rotation; // 旋转角度
  double scale; // 放比例

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
    this.scale = 1.0,
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

  /// 用当前 position / rotation / scale 更新 Matrix4
  void updateMatrix4() {
    // position 为元素左上角；这里构造一个围绕元素中心的变换矩阵
    final cx = position.dx + width / 2;
    final cy = position.dy + height / 2;

    transform = Matrix4.identity()
      // 1) 平移到元素中心
      ..translateByVector3(Vector3(cx, cy, 0))
      // 2) 旋转（围绕中心）
      ..rotateZ(rotation)
      // 3) 缩放（围绕中心）
      ..scaleByVector3(Vector3(scale, scale, 1))
      // 4) 把原点移回左上角
      ..translateByVector3(Vector3(-width / 2, -height / 2, 0));
  }

  /// 元素本地坐标系下的矩形（以左上角为原点）
  Rect get localRect => Rect.fromLTWH(0, 0, width, height);

  /// 元素本地坐标系下的四个顶点（以左上角为原点）
  /// 顺序：TL, TR, BR, BL
  List<Offset> get localCorners => [
    const Offset(0, 0),
    Offset(width, 0),
    Offset(width, height),
    Offset(0, height),
  ];
}
