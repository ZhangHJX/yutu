import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ScreenUtil封装类，提供简化的屏幕适配方法
class ScreenTools {
  /// 获取屏幕宽度
  static double get screenWidth => ScreenUtil().screenWidth;

  /// 获取屏幕高度
  static double get screenHeight => ScreenUtil().screenHeight;

  /// 获取状态栏高度
  static double get statusBarHeight => ScreenUtil().statusBarHeight;

  /// 获取底部安全区域高度
  static double get bottomBarHeight => ScreenUtil().bottomBarHeight;

  /// 获取屏幕像素密度
  static double get pixelRatio => ScreenUtil().pixelRatio ?? 1.0;

  /// 获取屏幕密度
  static double get textScaleFactor => ScreenUtil().textScaleFactor;

  /// 获取屏幕方向
  static Orientation get orientation => ScreenUtil().orientation;

  /// 根据设计稿宽度适配
  static double w(double width) => width.w;

  /// 根据设计稿高度适配
  static double h(double height) => height.h;

  /// 根据设计稿尺寸适配
  static double r(double size) => size.r;

  /// 判断是否为平板
  static bool get isTablet => ScreenUtil().screenWidth >= 768;

  /// 判断是否为手机
  static bool get isPhone => ScreenUtil().screenWidth < 768;

  /// 判断是否为横屏
  static bool get isLandscape =>
      ScreenUtil().orientation == Orientation.landscape;

  /// 判断是否为竖屏
  static bool get isPortrait =>
      ScreenUtil().orientation == Orientation.portrait;

  /// 获取安全区域（需要传入context）
  static EdgeInsets getSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// 获取安全区域顶部
  static double getSafeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// 获取安全区域底部
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 获取安全区域左侧
  static double getSafeAreaLeft(BuildContext context) {
    return MediaQuery.of(context).padding.left;
  }

  /// 获取安全区域右侧
  static double getSafeAreaRight(BuildContext context) {
    return MediaQuery.of(context).padding.right;
  }

  static double getKeyboardHeight(
    BuildContext context,
    bool isKeyboardVisible,
  ) {
    return isKeyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 0.0;
  }
}
