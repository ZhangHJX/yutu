import 'package:flutter/material.dart';
import '../model/index.dart';

/// CanvasElement 深度克隆工具
class CanvasElementClone {
  /// 深度克隆 CanvasElement 对象
  /// 创建所有属性的完全副本，用于命令模式保存状态
  static CanvasElement clone(CanvasElement source) {
    return CanvasElement(
      id: source.id,
      type: source.type,
      width: source.width,
      height: source.height,
      position: Offset(source.position.dx, source.position.dy),
      text: source.text,
      imagePath: source.imagePath,
      fillColor: source.fillColor,
      borderColor: source.borderColor,
      borderWidth: source.borderWidth,
      fontFamily: source.fontFamily,
      fontSize: source.fontSize,
      fontWeight: source.fontWeight,
      textColor: source.textColor,
      lineHeight: source.lineHeight,
      fontSpace: source.fontSpace,
      align: source.align,
      isShawOpen: source.isShawOpen,
      shawColor: source.shawColor,
      shawX: source.shawX,
      shawY: source.shawY,
      blurValue: source.blurValue,
      // rotation: source.rotation,
      // cumulativeScale: source.cumulativeScale,
      // fixedScaleCenter: source.fixedScaleCenter != null
      //     ? Offset(source.fixedScaleCenter!.dx, source.fixedScaleCenter!.dy)
      //     : null,
      // initialWidth: source.initialWidth,
      // initialHeight: source.initialHeight,
      // visible: source.visible,
    );
  }
}
