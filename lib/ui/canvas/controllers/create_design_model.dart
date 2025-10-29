import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

enum ElementType { image, rectangle, ellipse, line, text }

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
  double width;
  double height;
  Offset position;
  String text;

  // 图片相关属性
  String imagePath;

  // 形状/文字相关属性
  String fillColor;
  String borderColor;
  double borderWidth;

  String fontFamily; // 字体
  double fontSize; // 字体大小
  FontWeight fontWeight; // 字重
  String textColor; // 字体颜色
  double lineHeight; // 行高/行间距（相对于fontSize的倍数）
  double fontSpace; // 字间距
  String fontColor; // 字体背景色
  TextAlign align;

  // 阴影相关
  bool isShawOpen;
  String shawColor;
  double shawX;
  double shawY;
  double blurValue;

  EditBoxData({
    required this.id,
    required this.type,
    required this.width,
    required this.height,
    required this.position,
    this.imagePath = '',
    this.text = '',
    this.fillColor = '#D8D8D8',
    this.borderColor = '#D8D8D8',
    this.borderWidth = 0,

    this.fontFamily = "Courier",
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.textColor = '#FFFFFF',
    this.lineHeight = 1.0,
    this.fontSpace = 0,
    this.fontColor = '#FFFFFF',
    this.align = TextAlign.center,

    this.shawColor = '#D8D8D8',
    this.shawX = 0,
    this.shawY = 0,
    this.blurValue = 0,
    this.isShawOpen = false,
  });
}


/*
方式一：使用预定义常量（推荐）
FontWeight.w100  // 最细 - Thin
FontWeight.w200  // 超轻 - Extra Light
FontWeight.w300  // 轻 - Light
FontWeight.w400  // 正常 - Normal/Regular（默认）
FontWeight.w500  // 中等 - Medium
FontWeight.w600  // 半粗 - Semi Bold
FontWeight.w700  // 粗体 - Bold
FontWeight.w800  // 超粗 - Extra Bold
FontWeight.w900  // 最粗 - Black
*/ 