part of '../element_gesture_manager.dart';

/// 第三类：文本元素相关手势逻辑
extension _TextElementGestureHelper on ElementGestureManager {
  /// 文本元素调整大小时的新尺寸计算
  Size _updateResizeForText(
    CanvasElement box,
    ElementInteractionState state,
    double adjustedDx,
    double adjustedDy,
  ) {
    double newWidth = state.resizeStartWidth;
    double newHeight = state.resizeStartHeight;

    final minTextSize = _calculateMinTextSize(box);
    final minWidth = minTextSize.width;
    final minHeight = minTextSize.height;

    switch (state.resizingHandle!) {
      case 'left':
      case 'right':
        if (state.resizingHandle == 'right') {
          newWidth = (state.resizeStartWidth + adjustedDx).clamp(
            minWidth,
            ElementGestureManager.maxSize,
          );
        } else {
          newWidth = (state.resizeStartWidth - adjustedDx).clamp(
            minWidth,
            ElementGestureManager.maxSize,
          );
        }

        final textSize = TextMeasureUtil.measureTextWithWidth(
          text: box.text,
          fontSize: box.fontSize,
          fontFamily: box.fontFamily,
          fontWeight: box.fontWeight,
          letterSpacing: box.fontSpace,
          lineHeight: box.lineHeight,
          maxWidth: newWidth,
        );
        newHeight =
            textSize.height.clamp(minHeight, ElementGestureManager.maxSize);
        break;

      case 'top-left':
      case 'top-right':
      case 'bottom-left':
      case 'bottom-right':
        final scaleX = state.resizingHandle!.contains('right')
            ? (state.resizeStartWidth + adjustedDx) / state.resizeStartWidth
            : (state.resizeStartWidth - adjustedDx) / state.resizeStartWidth;
        final scaleY = state.resizingHandle!.contains('bottom')
            ? (state.resizeStartHeight + adjustedDy) / state.resizeStartHeight
            : (state.resizeStartHeight - adjustedDy) /
                state.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;

        final singleLineSize = TextMeasureUtil.measureText(
          text: box.text,
          fontSize: state.resizeStartFontSize,
          fontFamily: box.fontFamily,
          fontWeight: box.fontWeight,
          letterSpacing: state.resizeStartFontSpace,
          lineHeight: state.resizeStartLineHeight,
        );
        final isMultiLine = state.resizeStartWidth < singleLineSize.width;

        if (isMultiLine) {
          final scaledWidth = state.resizeStartWidth * scale;
          final scaledFontSize = state.resizeStartFontSize * scale;
          final scaledFontSpace = state.resizeStartFontSpace * scale;

          final finalFontSize =
              math.max(scaledFontSize, ElementGestureManager.minFontSize);
          final finalFontSpace = math.max(scaledFontSpace, 0.0);

          final finalWidth = (scaledFontSize >= ElementGestureManager.minFontSize)
              ? scaledWidth
              : (state.resizeStartWidth *
                  (ElementGestureManager.minFontSize /
                      state.resizeStartFontSize));

          final textSize = TextMeasureUtil.measureTextWithWidth(
            text: box.text,
            fontSize: finalFontSize,
            fontFamily: box.fontFamily,
            fontWeight: box.fontWeight,
            letterSpacing: finalFontSpace,
            lineHeight: state.resizeStartLineHeight,
            maxWidth: finalWidth,
          );

          newWidth = math.max(finalWidth, 0.0)
              .clamp(0.0, ElementGestureManager.maxSize);
          newHeight = math.max(textSize.height, 0.0)
              .clamp(0.0, ElementGestureManager.maxSize);
          box.fontSize = finalFontSize
              .clamp(ElementGestureManager.minFontSize, 200.0);
          box.fontSpace = finalFontSpace;
        } else {
          newWidth = (state.resizeStartWidth * scale).clamp(
            minWidth,
            ElementGestureManager.maxSize,
          );
          newHeight = (newWidth / state.resizeAspectRatio).clamp(
            minHeight,
            ElementGestureManager.maxSize,
          );
          newWidth = (newHeight * state.resizeAspectRatio).clamp(
            minWidth,
            ElementGestureManager.maxSize,
          );
          final actualScale = newWidth / state.resizeStartWidth;
          box.fontSize = (state.resizeStartFontSize * actualScale).clamp(
            ElementGestureManager.minFontSize,
            200.0,
          );
        }
        break;
      default:
        break;
    }

    return Size(newWidth, newHeight);
  }

  /// 双指缩放文本元素
  void _applyScaleForText(
    CanvasElement box,
    ElementInteractionState state,
  ) {
    final minTextSize = _calculateMinTextSize(box);
    final minWidth = minTextSize.width;
    final minHeight = minTextSize.height;

    final newWidth = (state.initialWidth * box.scale).clamp(
      minWidth,
      double.infinity,
    );
    final newHeight = (state.initialHeight * box.scale).clamp(
      minHeight,
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

    // 同时缩放字体大小
    box.fontSize = (state.initialFontSize * box.scale)
        .clamp(ElementGestureManager.minFontSize, double.infinity);
  }

  /// 根据最小字体大小计算文本框的最小尺寸
  /// [box] 文本框数据
  /// 返回最小宽度和最小高度
  Size _calculateMinTextSize(CanvasElement box) {
    // 如果没有文本，返回默认最小值
    if (box.text.isEmpty) {
      return Size(
        ElementGestureManager.minBoxSize,
        ElementGestureManager.minBoxSize,
      );
    }

    // 使用最小字体大小计算文本的最小尺寸
    // 先计算单行时的最小宽度
    final singleLineSize = TextMeasureUtil.measureText(
      text: box.text,
      fontSize: ElementGestureManager.minFontSize,
      fontFamily: box.fontFamily,
      fontWeight: box.fontWeight,
      letterSpacing: box.fontSpace,
      lineHeight: box.lineHeight,
    );

    // 如果单行宽度太小，使用默认最小值
    if (singleLineSize.width < ElementGestureManager.minBoxSize) {
      return Size(
        ElementGestureManager.minBoxSize,
        ElementGestureManager.minBoxSize > singleLineSize.height
            ? ElementGestureManager.minBoxSize
            : singleLineSize.height,
      );
    }

    // 使用当前文本框宽度（或单行宽度，取较小值）来计算多行文本的高度
    final maxWidth = math.min(box.width, singleLineSize.width);
    final minTextSize = TextMeasureUtil.measureTextWithWidth(
      text: box.text,
      fontSize: ElementGestureManager.minFontSize,
      fontFamily: box.fontFamily,
      fontWeight: box.fontWeight,
      letterSpacing: box.fontSpace,
      lineHeight: box.lineHeight,
      maxWidth: maxWidth,
    );

    // 确保最小尺寸不小于默认值
    return Size(
      math.max(ElementGestureManager.minBoxSize, minTextSize.width),
      math.max(ElementGestureManager.minBoxSize, minTextSize.height),
    );
  }
}


