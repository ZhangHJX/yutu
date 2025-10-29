import 'package:flutter/material.dart';

import 'colors.dart';

/// 一级标题
/// 黑色(333333)文本样式
TextStyle text333333({
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  TextDecoration? decoration,
  List<Shadow>? shadows,
  FontStyle? fontStyle,
  double? letterSpacing,
  bool ellipsis = false,
}) => TextStyle(
  color: cff333333,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  decoration: decoration,
  shadows: shadows,
  fontStyle: fontStyle,
  letterSpacing: letterSpacing,
  overflow: ellipsis ? TextOverflow.ellipsis : null,
);

TextStyle text474747({
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  TextDecoration? decoration,
  List<Shadow>? shadows,
  FontStyle? fontStyle,
  double? letterSpacing,
  bool ellipsis = false,
}) => TextStyle(
  color: cff474747,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  decoration: decoration,
  shadows: shadows,
  fontStyle: fontStyle,
  letterSpacing: letterSpacing,
  overflow: ellipsis ? TextOverflow.ellipsis : null,
);

/// 二级副文案
/// 灰色(545454)文本样式
TextStyle text54545D({
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  TextDecoration? decoration,
  List<Shadow>? shadows,
  FontStyle? fontStyle,
  double? letterSpacing,
  bool ellipsis = false,
}) => TextStyle(
  color: cff545454,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  decoration: decoration,
  shadows: shadows,
  fontStyle: fontStyle,
  letterSpacing: letterSpacing,
  overflow: ellipsis ? TextOverflow.ellipsis : null,
);

/// 三级副文案
/// 灰色(989897)文本样式
TextStyle text989897({
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  TextDecoration? decoration,
  List<Shadow>? shadows,
  FontStyle? fontStyle,
  double? letterSpacing,
  bool ellipsis = false,
}) => TextStyle(
  color: cff989897,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  decoration: decoration,
  shadows: shadows,
  fontStyle: fontStyle,
  letterSpacing: letterSpacing,
  overflow: ellipsis ? TextOverflow.ellipsis : null,
);
