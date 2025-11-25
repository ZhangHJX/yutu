part of 'element_gesture_manager.dart';

/// 第二类：形状元素（矩形、椭圆、线段）相关手势逻辑
extension _ShapeElementGestureHelper on ElementGestureManager {
  /// 计算形状元素在调整大小时的新尺寸
  Size _updateResizeForShape(
    CanvasElement box,
    ElementInteractionState state,
    double adjustedDx,
    double adjustedDy,
  ) {
    // 线段不允许通过四个角控制点调整尺寸，保持原尺寸不变
    if (box.type == ElementType.line &&
        (state.resizingHandle == 'top-left' ||
            state.resizingHandle == 'top-right' ||
            state.resizingHandle == 'bottom-right' ||
            state.resizingHandle == 'bottom-left')) {
      return Size(state.resizeStartWidth, state.resizeStartHeight);
    }

    // 其他形状与图片共用非文本尺寸计算逻辑
    return _updateResizeForNonText(
      box,
      state,
      adjustedDx,
      adjustedDy,
    );
  }

  /// 双指缩放形状元素
  void _applyScaleForShape(
    CanvasElement box,
    ElementInteractionState state,
  ) {
    // 当前形状缩放逻辑与图片一致，后续如果有差异可在此扩展
    _applyScaleForNonText(box, state);
  }
}


