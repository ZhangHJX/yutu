import 'package:flutter/material.dart';

/// 安全区域底部
class CSafeBottom extends StatelessWidget {
  const CSafeBottom({
    required this.child,
    super.key,
    this.minTop,
    this.minBottom,
    this.minVertical,
    this.minLeft,
    this.minRight,
    this.minHorizontal,
    this.color,
    this.decoration,
    this.minimum,
  }) : assert(decoration == null || color == null, 'decoration和color不能同时设置'),
       assert(
         minimum == null ||
             (minTop == null &&
                 minBottom == null &&
                 minVertical == null &&
                 minLeft == null &&
                 minRight == null &&
                 minHorizontal == null),
         'minimum 和 minTop/minBottom/minVertical/minLeft/minRight/minHorizontal 不能同时设置',
       );

  final Widget child;

  /// 最小顶部间距, 如果为null, 则使用minVertical
  final double? minTop;

  /// 最小底部间距, 如果为null, 则使用minVertical
  final double? minBottom;

  /// 最小垂直间距
  final double? minVertical;

  /// 最小左边间距, 如果为null, 则使用minHorizontal
  final double? minLeft;

  /// 最小右边间距, 如果为null, 则使用minHorizontal
  final double? minRight;

  /// 最小水平间距
  final double? minHorizontal;

  /// 背景色
  final Color? color;

  final BoxDecoration? decoration;

  final EdgeInsets? minimum;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration ?? BoxDecoration(color: color),
      child: SafeArea(
        top: false,
        minimum:
            minimum ??
            EdgeInsets.only(
              top: minTop ?? minVertical ?? 0,
              bottom: minBottom ?? minVertical ?? 0,
              left: minLeft ?? minHorizontal ?? 0,
              right: minRight ?? minHorizontal ?? 0,
            ),
        child: child,
      ),
    );
  }
}
