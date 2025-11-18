import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/index.dart';
import 'dart:math' as math;

class CanvalsEditBoxUtil {
  // 辅助方法：获取调整大小控制点的全局位置
  // static Map<String, Offset> getResizeHandleCenters(CanvasElement data) {
  //   // 外层容器始终包含边框
  //   final totalWidth = data.width + editBorderWidth * 2;
  //   final totalHeight = data.height + editBorderWidth * 2;

  //   // 控制点相对于容器左上角的位置（包含边框）
  //   final localPositions = {
  //     // 四个角点
  //     'top-left': Offset(-1.5, -1.5), // 左上角
  //     'top-right': Offset(totalWidth - 4.5, 0), // 右上角
  //     'bottom-left': Offset(-1.5, totalHeight - 4.5), // 左下角
  //     'bottom-right': Offset(totalWidth - 4.5, totalHeight - 3), // 右下角
  //     // 四个边中点
  //     'left': Offset(-1.5, totalHeight / 2 - 3), // 左边中点
  //     'right': Offset(totalWidth - 4.5, totalHeight / 2 - 1.5), // 右边中点
  //     'top': Offset(totalWidth / 2, -1.5), // 上边中点
  //     'bottom': Offset(totalWidth / 2, totalHeight - 4.5), // 下边中点
  //   };

  //   // final cos = math.cos(data.rotation);
  //   // final sin = math.sin(data.rotation);

  //   // 【关键修复】使用与内容相同的旋转中心点
  //   // 内容的旋转中心：data.position + (width/2, height/2)
  //   // 而不是包含边框的容器中心
  //   final centerX = data.position.dx + data.width / 2;
  //   final centerY = data.position.dy + data.height / 2;

  //   // 边框容器的左上角位置（相对于内容左上角的偏移）
  //   final borderOffsetX = -editBorderWidth;
  //   final borderOffsetY = -editBorderWidth;

  //   return localPositions.map((key, localPos) {
  //     // 控制点的本地位置是相对于边框容器左上角的
  //     // 需要转换为相对于内容中心的坐标
  //     // 首先转换为相对于边框容器中心的坐标
  //     final relToBorderCenterX = localPos.dx - totalWidth / 2;
  //     final relToBorderCenterY = localPos.dy - totalHeight / 2;

  //     // 边框容器中心相对于内容中心的偏移
  //     // 内容中心在边框容器中心的位置：内容中心 = 边框中心 - (borderOffset + editBorderWidth)
  //     // 实际上：边框中心 = 内容中心 + editBorderWidth
  //     // 所以相对于内容中心的坐标：
  //     final relX = relToBorderCenterX + editBorderWidth;
  //     final relY = relToBorderCenterY + editBorderWidth;

  //     // 应用旋转（围绕内容中心旋转）
  //     // final rotatedX = relX * cos - relY * sin;
  //     // final rotatedY = relX * sin + relY * cos;

  //     // 转换为全局坐标
  //     return MapEntry(key, Offset(centerX + rotatedX, centerY + rotatedY));
  //   });
  // }

  // 辅助方法：获取旋转按钮的全局位置（用于外部判断点击）
  // static Offset getRotationButtonCenter(CanvasElement data) {
  //   // 旋转按钮在容器底部中心，有padding
  //   // 外层容器始终包含边框
  //   final totalWidth = data.width + editBorderWidth * 2;
  //   final totalHeight = data.height + editBorderWidth * 2;

  //   // 【关键】按钮应该位于元素底部中心的正下方（在未旋转的坐标系中）
  //   // 相对于边框容器中心的位置（本地坐标系，未旋转）
  //   final buttonLocalX = 0.0; // 在边框容器中心的x坐标（水平居中）
  //   final buttonLocalY =
  //       totalHeight / 2 + rotationButtonPadding + rotationButtonSize / 2;

  //   // 【关键修复】使用与内容相同的旋转中心点
  //   final centerX = data.position.dx + data.width / 2;
  //   final centerY = data.position.dy + data.height / 2;

  //   // 按钮相对于边框容器中心的坐标需要转换为相对于内容中心的坐标
  //   // 边框容器中心相对于内容中心的偏移是 +editBorderWidth
  //   final relX = buttonLocalX + editBorderWidth;
  //   final relY = buttonLocalY + editBorderWidth;

  //   // 应用旋转（围绕内容中心旋转）- 这只是计算位置，不是旋转按钮本身
  //   final cos = math.cos(data.rotation);
  //   final sin = math.sin(data.rotation);
  //   final rotatedX = relX * cos - relY * sin;
  //   final rotatedY = relX * sin + relY * cos;

  //   // 转换为全局坐标
  //   return Offset(centerX + rotatedX, centerY + rotatedY);
  // }
}
