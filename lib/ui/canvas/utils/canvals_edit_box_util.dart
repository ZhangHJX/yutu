import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../controllers/create_design_model.dart';
import 'dart:math' as math;

class CanvalsEditBoxUtil {
  // 辅助方法：获取调整大小控制点的全局位置
  static Map<String, Offset> getResizeHandleCenters(EditBoxData data) {
    // 外层容器始终包含边框
    final totalWidth = data.width + editBorderWidth * 2;
    final totalHeight = data.height + editBorderWidth * 2;

    // 控制点相对于容器左上角的位置
    final localPositions = {
      // 四个角点
      'top-left': Offset(-1.5, -1.5), // 左上角
      'top-right': Offset(totalWidth - 4.5, 0), // 右上角
      'bottom-left': Offset(-1.5, totalHeight - 4.5), // 左下角
      'bottom-right': Offset(totalWidth - 4.5, totalHeight - 4.5), // 右下角
      // 四个边中点
      'left': Offset(-1.5, totalHeight / 2 - 3), // 左边中点
      'right': Offset(totalWidth - 4.5, totalHeight / 2), // 右边中点
      'top': Offset(totalWidth / 2, -1.5), // 上边中点
      'bottom': Offset(totalWidth / 2, totalHeight - 4.5), // 下边中点
    };

    final cos = math.cos(data.rotation);
    final sin = math.sin(data.rotation);

    // 容器中心的全局坐标（包含边框）
    final centerX = data.position.dx + totalWidth / 2;
    final centerY = data.position.dy + totalHeight / 2;

    return localPositions.map((key, localPos) {
      // 相对于中心的坐标
      final relX = localPos.dx - totalWidth / 2;
      final relY = localPos.dy - totalHeight / 2;

      // 应用旋转
      final rotatedX = relX * cos - relY * sin;
      final rotatedY = relX * sin + relY * cos;

      // 转换为全局坐标
      return MapEntry(key, Offset(centerX + rotatedX, centerY + rotatedY));
    });
  }

  // 辅助方法：获取旋转按钮的全局位置（用于外部判断点击）
  static Offset getRotationButtonCenter(EditBoxData data) {
    // 旋转按钮在容器底部中心，有padding
    // 外层容器始终包含边框
    final totalWidth = data.width + editBorderWidth * 2;
    final totalHeight = data.height + editBorderWidth * 2;

    // 相对于容器中心的位置
    final buttonLocalX = 0.0; // 在中心的x坐标
    final buttonLocalY =
        totalHeight / 2 + rotationButtonPadding + rotationButtonSize / 2;

    // 应用旋转（围绕中心旋转）
    final cos = math.cos(data.rotation);
    final sin = math.sin(data.rotation);
    final rotatedX = buttonLocalX * cos - buttonLocalY * sin;
    final rotatedY = buttonLocalX * sin + buttonLocalY * cos;

    // 转换为全局坐标（容器中心 + 旋转后的偏移）
    final centerX = data.position.dx + totalWidth / 2;
    final centerY = data.position.dy + totalHeight / 2;
    return Offset(centerX + rotatedX, centerY + rotatedY);
  }
}
