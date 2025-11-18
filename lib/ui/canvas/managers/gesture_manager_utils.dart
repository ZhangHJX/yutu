import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/index.dart';
import 'dart:math' as math;

class GestureManagerUtils {
  /// 检测点击了哪个元素或控制点
  static String? detectHitTarget(Offset position, CanvasElement box) {
    // 1. 检测旋转按钮
    // final rotationCenter = CanvalsEditBoxUtil.getRotationButtonCenter(box);
    // if (_isPointInCircle(position, rotationCenter, rotationButtonSize / 2)) {
    //   return 'rotate';
    // }

    // 2. 检测调整大小控制点
    // final resizeHandles = CanvalsEditBoxUtil.getResizeHandleCenters(box);
    // for (var entry in resizeHandles.entries) {
    //   if (_isPointInCircle(position, entry.value, editHitCircleSize / 2)) {
    //     return 'resize:${entry.key}';
    //   }
    // }

    // 3. 检测是否在元素内部
    // 外层容器始终包含边框
    // final totalWidth = box.width;
    // final totalHeight = box.height;

    // final localX = position.dx - box.position.dx;
    // final localY = position.dy - box.position.dy;

    // final cos = math.cos(-box.rotation);
    // final sin = math.sin(-box.rotation);
    // final unrotatedX = localX * cos - localY * sin;
    // final unrotatedY = localX * sin + localY * cos;

    // // 判断是否在外层容器内（包含边框区域）
    // if (unrotatedX >= 0 &&
    //     unrotatedX <= totalWidth &&
    //     unrotatedY >= 0 &&
    //     unrotatedY <= totalHeight) {
    //   return 'content';
    // }

    return null;
  }

  /// 检测点是否在圆内
  static bool _isPointInCircle(Offset point, Offset center, double radius) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return (dx * dx + dy * dy) <= (radius * radius);
  }

  /// 检查点击位置是否在画布内
  static bool isPointInCanvas(Offset position, Size? canvasSize) {
    if (canvasSize == null) {
      // 如果没有设置画布尺寸，默认允许
      return true;
    }

    return position.dx >= 0 &&
        position.dx <= canvasSize.width &&
        position.dy >= 0 &&
        position.dy <= canvasSize.height;
  }
}
