import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

enum ElementType { image, rectangle, ellipse, line, text }

// 画布模型
@JsonSerializable(explicitToJson: true)
class DesignCanvalsModel {
  final String id;
  final double width;
  final double height;
  final double canvasRatio;

  @JsonKey(name: 'canvasProperties')
  CanvasProperties properties; // 独立的画布属性

  final List<CanvasElement>? elements;

  DesignCanvalsModel({
    required this.canvasRatio,
    this.elements,
    required this.id,
    required this.width,
    required this.height,
    CanvasProperties? properties,
  }) : properties = properties ?? CanvasProperties();
}

// 画布属性类
class CanvasProperties {
  String fillColor;
  double fillAlpha;
  String borderColor;
  double borderWidth;
  double borderAlpha;
  bool isLock;
  bool isSelected;

  CanvasProperties({
    this.fillColor = '#FFFFFF',
    this.fillAlpha = 1.0,
    this.borderColor = '#BFBFBF',
    this.borderWidth = 1.0,
    this.borderAlpha = 1.0,
    this.isLock = true,
    this.isSelected = false,
  });

  // 深拷贝方法
  CanvasProperties copy() {
    return CanvasProperties(
      fillColor: fillColor,
      fillAlpha: fillAlpha,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderAlpha: borderAlpha,
      isLock: isLock,
    );
  }
}

// 所有的模型数据
@JsonSerializable(explicitToJson: true)
class CanvasElement {
  final String id;
  final ElementType type;
  double width;
  double height;
  Offset position;

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

  // 公共属性-图层相关属性
  bool visible; // 元素是否可见
  bool isLock; // 元素是否被锁

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
    required this.id,
    required this.type,
    required this.width,
    required this.height,
    required this.position,

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
    this.visible = true,
    this.isLock = false,

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
