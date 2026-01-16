import 'package:flutter/material.dart';
import '../model/index.dart';
import 'dart:math' as math;

/// 元素吸附辅助类：检测元素移动时与其他元素边缘的吸附
class ElementSnapHelper {
  /// 是否启用元素吸附功能
  static bool enabled = true;

  /// 吸附阈值（像素距离）
  static const double snapThreshold = 1;

  /// 中心点吸附的额外优先级（让中心对齐更容易触发）
  static const double centerSnapBonus = 1.5;

  /// 计算元素旋转后的AABB（轴对齐包围盒）
  ///
  /// [element] 要计算的元素
  /// [position] 元素的位置（可以是预测位置）
  ///
  /// 返回旋转后的最小包围矩形
  static Rect _getRotatedAABB(CanvasElement element, Offset position) {
    // 如果旋转角度很小，直接返回原始矩形（优化性能）
    if (element.rotation.abs() < 0.01) {
      return Rect.fromLTWH(
        position.dx,
        position.dy,
        element.width,
        element.height,
      );
    }

    // 计算元素中心点
    final cx = position.dx + element.width / 2;
    final cy = position.dy + element.height / 2;

    // 预计算旋转的三角函数值
    final cos = math.cos(element.rotation);
    final sin = math.sin(element.rotation);

    // 半宽和半高
    final hw = element.width / 2;
    final hh = element.height / 2;

    // 四个角点相对于中心的偏移（未旋转）
    final corners = [
      Offset(-hw, -hh), // 左上
      Offset(hw, -hh), // 右上
      Offset(hw, hh), // 右下
      Offset(-hw, hh), // 左下
    ];

    // 初始化边界值
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    // 对每个角点应用旋转，并更新边界
    for (final corner in corners) {
      // 应用旋转变换
      final rotatedX = corner.dx * cos - corner.dy * sin;
      final rotatedY = corner.dx * sin + corner.dy * cos;

      // 转换到世界坐标
      final worldX = cx + rotatedX;
      final worldY = cy + rotatedY;

      // 更新边界
      if (worldX < minX) minX = worldX;
      if (worldX > maxX) maxX = worldX;
      if (worldY < minY) minY = worldY;
      if (worldY > maxY) maxY = worldY;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 检测吸附信息
  ///
  /// [movingElement] 正在移动的元素
  /// [targetPosition] 元素的目标位置（未吸附前）
  /// [allElements] 画布上的所有元素
  /// [canvasSize] 画布尺寸（可选，用于延伸参考线）
  ///
  /// 返回：吸附后的位置和吸附参考线信息
  static SnapResult checkSnap(
    CanvasElement movingElement,
    Offset targetPosition,
    List<CanvasElement> allElements, {
    Size? canvasSize,
  }) {
    // 如果吸附功能未启用，直接返回原始位置
    if (!enabled) {
      return SnapResult(
        position: targetPosition,
        snapLines: [],
        hasSnap: false,
      );
    }

    // 计算移动元素旋转后的AABB（轴对齐包围盒）
    final movingBounds = _getRotatedAABB(movingElement, targetPosition);

    // 被移动元素的边缘位置（使用AABB）
    final movingLeft = movingBounds.left;
    final movingRight = movingBounds.right;
    final movingTop = movingBounds.top;
    final movingBottom = movingBounds.bottom;
    final movingCenterX = movingBounds.center.dx;
    final movingCenterY = movingBounds.center.dy;

    double? snapX;
    double? snapY;
    final List<SnapLine> snapLines = [];

    double minXDistance = double.infinity;
    double minYDistance = double.infinity;

    // 计算画布边界（用于延伸参考线）
    double canvasMinY = double.infinity;
    double canvasMaxY = double.negativeInfinity;
    double canvasMinX = double.infinity;
    double canvasMaxX = double.negativeInfinity;

    // 遍历所有元素计算边界（使用AABB确保旋转元素也被正确包含）
    for (final element in allElements) {
      if (element.hidden || element.locked) continue;

      final bounds = _getRotatedAABB(element, element.position);

      if (bounds.top < canvasMinY) canvasMinY = bounds.top;
      if (bounds.bottom > canvasMaxY) canvasMaxY = bounds.bottom;
      if (bounds.left < canvasMinX) canvasMinX = bounds.left;
      if (bounds.right > canvasMaxX) canvasMaxX = bounds.right;
    }

    // 包含移动元素的边界
    if (movingBounds.top < canvasMinY) canvasMinY = movingBounds.top;
    if (movingBounds.bottom > canvasMaxY) canvasMaxY = movingBounds.bottom;
    if (movingBounds.left < canvasMinX) canvasMinX = movingBounds.left;
    if (movingBounds.right > canvasMaxX) canvasMaxX = movingBounds.right;

    // 遍历所有其他元素，找出最近的吸附边缘
    for (final element in allElements) {
      // 跳过自己、隐藏的和锁定的元素
      if (element.id == movingElement.id || element.hidden || element.locked) {
        continue;
      }

      // 计算目标元素旋转后的AABB
      final targetBounds = _getRotatedAABB(element, element.position);

      // 目标元素的边缘位置（使用AABB）
      final targetLeft = targetBounds.left;
      final targetRight = targetBounds.right;
      final targetTop = targetBounds.top;
      final targetBottom = targetBounds.bottom;
      final targetCenterX = targetBounds.center.dx;
      final targetCenterY = targetBounds.center.dy;

      // 检测水平方向的吸附（X轴）
      _checkHorizontalSnap(
        movingLeft: movingLeft,
        movingRight: movingRight,
        movingCenterX: movingCenterX,
        targetLeft: targetLeft,
        targetRight: targetRight,
        targetCenterX: targetCenterX,
        targetTop: targetTop,
        targetBottom: targetBottom,
        canvasMinY: canvasMinY,
        canvasMaxY: canvasMaxY,
        minDistance: minXDistance,
        onSnap: (offset, distance, line) {
          if (distance < minXDistance) {
            minXDistance = distance;
            snapX = offset;
            snapLines.removeWhere((l) => l.isVertical);
            snapLines.add(line);
          }
        },
      );

      // 检测垂直方向的吸附（Y轴）
      _checkVerticalSnap(
        movingTop: movingTop,
        movingBottom: movingBottom,
        movingCenterY: movingCenterY,
        targetTop: targetTop,
        targetBottom: targetBottom,
        targetCenterY: targetCenterY,
        targetLeft: targetLeft,
        targetRight: targetRight,
        canvasMinX: canvasMinX,
        canvasMaxX: canvasMaxX,
        minDistance: minYDistance,
        onSnap: (offset, distance, line) {
          if (distance < minYDistance) {
            minYDistance = distance;
            snapY = offset;
            snapLines.removeWhere((l) => !l.isVertical);
            snapLines.add(line);
          }
        },
      );
    }

    // 返回吸附结果
    final snappedPosition = Offset(
      snapX ?? targetPosition.dx,
      snapY ?? targetPosition.dy,
    );

    return SnapResult(
      position: snappedPosition,
      snapLines: snapLines,
      hasSnap: snapX != null || snapY != null,
    );
  }

  /// 检测水平方向的吸附
  static void _checkHorizontalSnap({
    required double movingLeft,
    required double movingRight,
    required double movingCenterX,
    required double targetLeft,
    required double targetRight,
    required double targetCenterX,
    required double targetTop,
    required double targetBottom,
    required double canvasMinY,
    required double canvasMaxY,
    required double minDistance,
    required void Function(double offset, double distance, SnapLine line)
    onSnap,
  }) {
    // 使用画布边界作为参考线的延伸范围
    final lineStart = canvasMinY - 100;
    final lineEnd = canvasMaxY + 100;

    // 检测左边缘对齐目标左边缘
    final leftToLeftDistance = (movingLeft - targetLeft).abs();
    if (leftToLeftDistance < snapThreshold &&
        leftToLeftDistance < minDistance) {
      onSnap(
        targetLeft,
        leftToLeftDistance,
        SnapLine(
          isVertical: true,
          position: targetLeft,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测左边缘对齐目标右边缘
    final leftToRightDistance = (movingLeft - targetRight).abs();
    if (leftToRightDistance < snapThreshold &&
        leftToRightDistance < minDistance) {
      onSnap(
        targetRight,
        leftToRightDistance,
        SnapLine(
          isVertical: true,
          position: targetRight,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测右边缘对齐目标左边缘
    final rightToLeftDistance = (movingRight - targetLeft).abs();
    if (rightToLeftDistance < snapThreshold &&
        rightToLeftDistance < minDistance) {
      onSnap(
        targetLeft - (movingRight - movingLeft),
        rightToLeftDistance,
        SnapLine(
          isVertical: true,
          position: targetLeft,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测右边缘对齐目标右边缘
    final rightToRightDistance = (movingRight - targetRight).abs();
    if (rightToRightDistance < snapThreshold &&
        rightToRightDistance < minDistance) {
      onSnap(
        targetRight - (movingRight - movingLeft),
        rightToRightDistance,
        SnapLine(
          isVertical: true,
          position: targetRight,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测中心对齐目标中心（水平）- 给予更高优先级
    final centerToCenterXDistance = (movingCenterX - targetCenterX).abs();
    // 中心对齐使用更大的阈值（优先级更高）
    if (centerToCenterXDistance < snapThreshold * centerSnapBonus &&
        centerToCenterXDistance < minDistance) {
      onSnap(
        targetCenterX - (movingCenterX - movingLeft),
        centerToCenterXDistance * 0.8, // 降低距离值，提高优先级
        SnapLine(
          isVertical: true,
          position: targetCenterX,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }
  }

  /// 检测垂直方向的吸附
  static void _checkVerticalSnap({
    required double movingTop,
    required double movingBottom,
    required double movingCenterY,
    required double targetTop,
    required double targetBottom,
    required double targetCenterY,
    required double targetLeft,
    required double targetRight,
    required double canvasMinX,
    required double canvasMaxX,
    required double minDistance,
    required void Function(double offset, double distance, SnapLine line)
    onSnap,
  }) {
    // 使用画布边界作为参考线的延伸范围
    final lineStart = canvasMinX - 100;
    final lineEnd = canvasMaxX + 100;

    // 检测上边缘对齐目标上边缘
    final topToTopDistance = (movingTop - targetTop).abs();
    if (topToTopDistance < snapThreshold && topToTopDistance < minDistance) {
      onSnap(
        targetTop,
        topToTopDistance,
        SnapLine(
          isVertical: false,
          position: targetTop,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测上边缘对齐目标下边缘
    final topToBottomDistance = (movingTop - targetBottom).abs();
    if (topToBottomDistance < snapThreshold &&
        topToBottomDistance < minDistance) {
      onSnap(
        targetBottom,
        topToBottomDistance,
        SnapLine(
          isVertical: false,
          position: targetBottom,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测下边缘对齐目标上边缘
    final bottomToTopDistance = (movingBottom - targetTop).abs();
    if (bottomToTopDistance < snapThreshold &&
        bottomToTopDistance < minDistance) {
      onSnap(
        targetTop - (movingBottom - movingTop),
        bottomToTopDistance,
        SnapLine(
          isVertical: false,
          position: targetTop,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测下边缘对齐目标下边缘
    final bottomToBottomDistance = (movingBottom - targetBottom).abs();
    if (bottomToBottomDistance < snapThreshold &&
        bottomToBottomDistance < minDistance) {
      onSnap(
        targetBottom - (movingBottom - movingTop),
        bottomToBottomDistance,
        SnapLine(
          isVertical: false,
          position: targetBottom,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }

    // 检测中心对齐目标中心（垂直）- 给予更高优先级
    final centerToCenterYDistance = (movingCenterY - targetCenterY).abs();
    // 中心对齐使用更大的阈值（优先级更高）
    if (centerToCenterYDistance < snapThreshold * centerSnapBonus &&
        centerToCenterYDistance < minDistance) {
      onSnap(
        targetCenterY - (movingCenterY - movingTop),
        centerToCenterYDistance * 0.8, // 降低距离值，提高优先级
        SnapLine(
          isVertical: false,
          position: targetCenterY,
          start: lineStart,
          end: lineEnd,
        ),
      );
    }
  }
}

/// 吸附结果
class SnapResult {
  /// 吸附后的位置
  final Offset position;

  /// 吸附参考线列表
  final List<SnapLine> snapLines;

  /// 是否发生了吸附
  final bool hasSnap;

  SnapResult({
    required this.position,
    required this.snapLines,
    required this.hasSnap,
  });
}

/// 吸附参考线
class SnapLine {
  /// 是否为垂直线（true=垂直，false=水平）
  final bool isVertical;

  /// 参考线的位置（垂直线的x坐标，水平线的y坐标）
  final double position;

  /// 参考线的起始位置（垂直线的y坐标，水平线的x坐标）
  final double start;

  /// 参考线的结束位置（垂直线的y坐标，水平线的x坐标）
  final double end;

  SnapLine({
    required this.isVertical,
    required this.position,
    required this.start,
    required this.end,
  });
}
