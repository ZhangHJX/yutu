part of '../element_gesture_manager.dart';

/// 第一类：图片元素相关手势逻辑
extension _ImageElementGestureHelper on ElementGestureManager {
  /// 计算图片元素在调整大小时的新尺寸
  Size _updateResizeForImage(
    CanvasElement box,
    ElementInteractionState state,
    double adjustedDx,
    double adjustedDy,
  ) {
    return _updateResizeForNonText(
      box,
      state,
      adjustedDx,
      adjustedDy,
    );
  }

  /// 双指缩放图片元素
  void _applyScaleForImage(
    CanvasElement box,
    ElementInteractionState state,
  ) {
    _applyScaleForNonText(box, state);
  }

  /// 非文本类型（图片 / 形状）的通用尺寸计算逻辑
  Size _updateResizeForNonText(
    CanvasElement box,
    ElementInteractionState state,
    double adjustedDx,
    double adjustedDy,
  ) {
    double newWidth = state.resizeStartWidth;
    double newHeight = state.resizeStartHeight;

    switch (state.resizingHandle!) {
      case 'top-left':
        final scaleX =
            (state.resizeStartWidth - adjustedDx) / state.resizeStartWidth;
        final scaleY =
            (state.resizeStartHeight - adjustedDy) / state.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (state.resizeStartWidth * scale)
            .clamp(50.0, ElementGestureManager.maxSize);
        newHeight =
            (newWidth / state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        newWidth =
            (newHeight * state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        break;
      case 'top':
        newHeight = (state.resizeStartHeight - adjustedDy).clamp(
          box.type == ElementType.line ? 20.0 : 50.0,
          ElementGestureManager.maxSize,
        );
        break;
      case 'top-right':
        final scaleX =
            (state.resizeStartWidth + adjustedDx) / state.resizeStartWidth;
        final scaleY =
            (state.resizeStartHeight - adjustedDy) / state.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (state.resizeStartWidth * scale)
            .clamp(50.0, ElementGestureManager.maxSize);
        newHeight =
            (newWidth / state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        newWidth =
            (newHeight * state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        break;
      case 'right':
        newWidth = (state.resizeStartWidth + adjustedDx)
            .clamp(50.0, ElementGestureManager.maxSize);
        break;
      case 'bottom-right':
        final scaleX =
            (state.resizeStartWidth + adjustedDx) / state.resizeStartWidth;
        final scaleY =
            (state.resizeStartHeight + adjustedDy) / state.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (state.resizeStartWidth * scale)
            .clamp(50.0, ElementGestureManager.maxSize);
        newHeight =
            (newWidth / state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        newWidth =
            (newHeight * state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        break;
      case 'bottom':
        newHeight = (state.resizeStartHeight + adjustedDy).clamp(
          box.type == ElementType.line ? 20.0 : 50.0,
          ElementGestureManager.maxSize,
        );
        break;
      case 'bottom-left':
        final scaleX =
            (state.resizeStartWidth - adjustedDx) / state.resizeStartWidth;
        final scaleY =
            (state.resizeStartHeight + adjustedDy) / state.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (state.resizeStartWidth * scale)
            .clamp(50.0, ElementGestureManager.maxSize);
        newHeight =
            (newWidth / state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        newWidth =
            (newHeight * state.resizeAspectRatio)
                .clamp(50.0, ElementGestureManager.maxSize);
        break;
      case 'left':
        newWidth = (state.resizeStartWidth - adjustedDx)
            .clamp(50.0, ElementGestureManager.maxSize);
        break;
    }

    return Size(newWidth, newHeight);
  }

  /// 非文本类型（图片 / 形状）的通用缩放逻辑
  void _applyScaleForNonText(
    CanvasElement box,
    ElementInteractionState state,
  ) {
    final newWidth = (state.initialWidth * box.scale).clamp(
      50.0,
      double.infinity,
    );
    final newHeight = (state.initialHeight * box.scale).clamp(
      50.0,
      double.infinity,
    );

    // 计算新的外层容器总尺寸（包含边框）
    final totalNewWidth = newWidth;
    final totalNewHeight = newHeight;

    // 使用包含边框的总尺寸来计算位置，确保缩放中心点正确
    final newPosition = Offset(
      state.fixedScaleCenter!.dx - totalNewWidth / 2,
      state.fixedScaleCenter!.dy - totalNewHeight / 2,
    );

    box.x = newPosition.dx;
    box.y = newPosition.dy;
    box.width = newWidth;
    box.height = newHeight;
  }
}


