import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/index.dart';
import 'dart:math' as math;

class GestureManagerUtils {
  
  /// 检测点击了哪个元素或控制点
  static String? detectHitTarget(Offset position, CanvasElement box) {
    // 1. 确保使用的是最新的变换矩阵
    box.updateMatrix4();
    // 2. 画布坐标 -> 元素本地坐标
    //    MatrixUtilsX.canvasToElement 会用 element.transform 的逆矩阵把点击点变换到元素局部坐标系
    final local = MatrixUtilsX.canvasToElement(position, box.transform);

    // 3. 在元素本地坐标系中做简单的矩形命中检测
    //    本地坐标以左上角 (0,0) 为原点，宽高为 box.width / box.height
    final bool hitContent =
        local.dx >= 0 &&
        local.dx <= box.width &&
        local.dy >= 0 &&
        local.dy <= box.height;

    if (hitContent) {
      return 'content';
    }

    // // 1. 检测旋转按钮
    // final rotationCenter = CanvalsEditBoxUtil.getRotationButtonCenter(box);
    // if (_isPointInCircle(position, rotationCenter, rotationButtonSize / 2)) {
    //   return 'rotate';
    // }

    // // 2. 检测调整大小控制点
    // final resizeHandles = CanvalsEditBoxUtil.getResizeHandleCenters(box);
    // for (var entry in resizeHandles.entries) {
    //   if (_isPointInCircle(position, entry.value, editHitCircleSize / 2)) {
    //     return 'resize:${entry.key}';
    //   }
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
