import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

part 'canvas_element.g.dart';

enum ElementType { image, rectangle, ellipse, line, text }

@JsonSerializable(explicitToJson: true)
class CanvasElement {
  String id;
  ElementType type;

  @JsonKey(defaultValue: 0)
  double x;
  @JsonKey(defaultValue: 0)
  double y;
  double width;
  double height;
  bool hidden; // 元素是否可见
  bool locked; // 元素是否被锁
  bool selected; // 是否被选中

  // 图片相关属性
  String fileName;
  double fileAlpha;

  // 形状相关属性
  String fillColor;
  double fillAlpha;

  // 文字相关属性
  String text;
  double fontSize;

  /// 字体ID（来自接口的FontInfoModel.id），用于标识使用的是哪个下载的字体
  /// 如果为null，表示使用系统默认字体
  @JsonKey(includeIfNull: false)
  int? fontId;

  /// Flutter使用的字体家族名（FontFamilyMeta.familyKey），用于实际渲染
  String fontFamily;

  /// 字重（OS/2表中的usWeightClass，100~900）
  /// 序列化时转换为int，反序列化时转换为FontWeight
  @JsonKey(
    fromJson: CanvasElement._fontWeightFromJson,
    toJson: CanvasElement._fontWeightToJson,
  )
  FontWeight fontWeight;

  @JsonKey(
    fromJson: CanvasElement._textAlignFromJson,
    toJson: CanvasElement._textAlignToJson,
  )
  TextAlign align;
  double lineHeight;
  double fontSpace;
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

  // 矩阵变换
  @JsonKey(includeFromJson: false, includeToJson: false)
  Matrix4 transform = Matrix4.identity();

  double rotation; // 旋转角度
  double scale; // 放比例

  CanvasElement({
    this.id = '',
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.hidden = false,
    this.locked = false,
    this.selected = false,

    this.fileName = '',
    this.fileAlpha = 1.0,

    this.fillAlpha = 1.0,
    this.fillColor = '#D8D8D8',

    this.text = '',
    this.fontId,
    this.fontFamily = "Courier",
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.lineHeight = 1.0,
    this.fontSpace = 0,
    this.align = TextAlign.left,
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
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  // 自动生成的 JSON 解析
  factory CanvasElement.fromJson(Map<String, dynamic> json) =>
      _$CanvasElementFromJson(json);

  /// 自动生成的 JSON 输出
  Map<String, dynamic> toJson() => _$CanvasElementToJson(this);

  // -----------------------
  // 自定义序列化方法（关键）
  // -----------------------

  // FontWeight
  /// 将int（100~900）转换为FontWeight
  static FontWeight _fontWeightFromJson(int value) {
    // 将OS/2表中的usWeightClass（100~900）转换为Flutter的FontWeight
    if (value <= 150) return FontWeight.w100;
    if (value <= 250) return FontWeight.w200;
    if (value <= 350) return FontWeight.w300;
    if (value <= 450) return FontWeight.w400;
    if (value <= 550) return FontWeight.w500;
    if (value <= 650) return FontWeight.w600;
    if (value <= 750) return FontWeight.w700;
    if (value <= 850) return FontWeight.w800;
    return FontWeight.w900;
  }

  /// 将FontWeight转换为int（100~900）
  static int _fontWeightToJson(FontWeight weight) {
    return weight.value;
  }

  // TextAlign
  static TextAlign _textAlignFromJson(int value) => TextAlign.values[value];
  static int _textAlignToJson(TextAlign align) =>
      TextAlign.values.indexOf(align);

  /// 用当前 position / rotation / scale 更新 Matrix4 position 为元素左上角；这里构造一个围绕元素中心的变换矩阵
  void updateMatrix4() {
    final cx = x + width / 2;
    final cy = y + height / 2;

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

  /// 元素本地坐标系下的四个顶点（以左上角为原点） 顺序：TL, TR, BR, BL
  List<Offset> get localCorners => [
    const Offset(0, 0),
    Offset(width, 0),
    Offset(width, height),
    Offset(0, height),
  ];

  Offset get position => Offset(x, y);
}
