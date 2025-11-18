import 'package:flutter/material.dart';
import '../model/canvas_model.dart';

/// 画布尺寸转换工具类
/// 用于将CanvasModel中的画布尺寸转换为屏幕显示尺寸
class CanvasSizeUtil {
  /// 从CanvasModel获取画布尺寸，并转换为屏幕显示尺寸
  ///
  /// [canvasModel] 画布模型，包含原始宽度和高度
  /// [availableWidth] 可用宽度
  /// [availableHeight] 可用高度
  ///
  /// 返回转换后的显示尺寸，保持画布的宽高比
  static Size convertToDisplaySize(
    CanvasModel canvasModel,
    double availableWidth,
    double availableHeight,
  ) {
    // 计算画布宽高比
    final canvasRatio = canvasModel.height / canvasModel.width;
    final availableRatio = availableWidth / availableHeight;

    double displayWidth;
    double displayHeight;

    if (canvasRatio > availableRatio) {
      // 画布更高，以高度为基准充满
      displayHeight = availableHeight;
      displayWidth = availableHeight * (canvasModel.width / canvasModel.height);
    } else {
      // 画布更宽，以宽度为基准充满
      displayWidth = availableWidth;
      displayHeight = availableWidth / canvasRatio;
    }

    return Size(displayWidth, displayHeight);
  }
}
