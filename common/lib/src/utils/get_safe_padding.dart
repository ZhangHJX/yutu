import 'dart:math';

import 'package:flutter/material.dart';

/// 获取指定方向的安全区padding
EdgeInsets getSafePadding(
  BuildContext context, {
  bool left = false,
  bool right = false,
  bool top = false,
  bool bottom = true,
  EdgeInsets minimum = .zero,
}) {
  final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
  var padding = EdgeInsets.zero;
  if (mediaQuery != null) {
    padding = mediaQuery.padding.copyWith(
      left: left ? null : 0,
      right: right ? null : 0,
      top: top ? null : 0,
      bottom: bottom ? null : 0,
    );
  }
  if (minimum != .zero) {
    padding = padding.copyWith(
      top: max(minimum.top, padding.top),
      bottom: max(minimum.bottom, padding.bottom),
      left: max(minimum.left, padding.left),
      right: max(minimum.right, padding.right),
    );
  }
  return padding;
}
