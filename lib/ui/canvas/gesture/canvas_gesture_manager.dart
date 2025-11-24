import 'package:flutter/material.dart';
import '../utils/text_measure_util.dart';
import '../history/canvas_history_manager.dart';
import 'element_interaction_state.dart';
import '../model/index.dart';
import 'dart:math' as math;

/// 画布手势管理器： 负责处理所有的手势交互逻辑
class CanvasGestureManager {
  // 缩放相关
  final Map<int, Offset> pointers = {};
  // 历史管理器
  CanvasHistoryManager? historyManager;
  // 拖动相关
  bool hasMoved = false;
  Offset? dragStartPosition;
  Offset? dragStartBoxPosition;
  static const double dragStartThreshold = 5.0; // 开始拖动的距离阈值

  // 交互状态
  String?
  currentInteraction; // 'drag', 'rotate', 'resize', 'scale', 'pending_drag_or_tap'

  double lastScale = 1.0;

  // 每个元素的交互状态缓存
  final Map<String, ElementInteractionState> _interactionStates = {};

  ElementInteractionState _stateForBox(CanvasElement box) {
    return _interactionStates.putIfAbsent(
      box.id,
      () => ElementInteractionState(),
    );
  }

  void clearInteractionState(String elementId) {
    _interactionStates.remove(elementId);
  }

  // 操作开始时的状态快照（用于历史记录）
  Offset? _operationStartPosition;
  double? _operationStartRotation;
  double? _operationStartWidth;
  double? _operationStartHeight;
  double? _operationStartCumulativeScale;
  double? _operationStartFontSize;
  double? _operationStartFontSpace;

  // 尺寸限制
  static const double maxSize = double.infinity;
  static const double minFontSize = 5.0; // 最小字体大小
  static const double minBoxSize = 5.0; // 最小文本框尺寸（用于非文本类型或后备）

  // 适配画布Matrix4缩放
  Matrix4 canvasMatrix = Matrix4.identity();
  void updateCanvasMatrix(Matrix4 matrix) {
    canvasMatrix = Matrix4.copy(matrix);
  }

  /// 处理指针按下事件
  void handlePointerDown(
    PointerDownEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    pointers[event.pointer] = event.localPosition;

    if (pointers.length == 1) {
      // 单指按下：如果之前有残留状态，先清理
      if (currentInteraction == 'scale') {
        _resetDragState();
        currentInteraction = null;
        debugPrint('⚠️ 单指按下时检测到残留的缩放状态，已重置');
      }
      _handleSinglePointerDown(event, boxes, selectedId);
    } else if (pointers.length == 2) {
      // 双指按下：清除拖动相关状态，准备进入缩放模式
      _resetDragState();
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      if (selectedBox.locked) {
        return;
      }
      _handleDoublePointerDown(boxes, selectedId);
    }
  }

  /// 处理单指按下
  void _handleSinglePointerDown(
    PointerDownEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    // 如果之前是缩放状态，确保完全重置所有状态
    if (currentInteraction == 'scale') {
      _resetDragState();
      currentInteraction = null;
      debugPrint('⚠️ 单指按下时检测到残留的缩放状态，已重置');
    }

    // 重置拖动状态并设置新的起始位置
    hasMoved = false;
    dragStartPosition =
        event.localPosition; // 使用 localPosition 而不是 position，保持一致性

    CanvasElement selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    final state = _stateForBox(selectedBox);
    final hitTarget = MatrixUtilsXGesture.detectHitTarget(
      event.position,
      selectedBox,
      canvasMatrix,
    );

    debugPrint('✅ 哈哈哈哈哈哈哈---$hitTarget');
    if (hitTarget != null) {
      if (selectedBox.locked) {
        return;
      }

      if (hitTarget == 'rotate') {
        // 开始旋转
        currentInteraction = 'rotate';
        hasMoved = true; // 判定为旋转操作
        state.rotateLastPosition = event.localPosition;
        // 保存操作开始时的状态
        _operationStartRotation = selectedBox.rotation;
        debugPrint('✅ 判定为旋转: $selectedId');
        return;
      } else if (hitTarget.startsWith('resize:')) {
        // 开始调整大小
        final handle = hitTarget.substring(7);
        currentInteraction = 'resize';
        hasMoved = true; // 判定为缩放操作
        // 保存操作开始时的状态
        _operationStartWidth = selectedBox.width;
        _operationStartHeight = selectedBox.height;
        _operationStartPosition = Offset(selectedBox.x, selectedBox.y);
        if (selectedBox.type == ElementType.text) {
          _operationStartFontSize = selectedBox.fontSize;
          _operationStartFontSpace = selectedBox.fontSpace;
        }
        _startResize(selectedBox, handle, event.localPosition);
        debugPrint('✅ 判定为缩放: $selectedId, 控制点: $handle');
        return;
      } else if (hitTarget == 'content') {
        // 待定状态：可能是拖动，也可能是点击取消激活
        currentInteraction = 'pending_drag_or_tap';
        dragStartBoxPosition = selectedBox.position;
        // 保存操作开始时的位置（用于历史记录）
        _operationStartPosition = Offset(selectedBox.x, selectedBox.y);
        // 初始化缩放中心点（外层容器包含边框）
        if (state.fixedScaleCenter == null) {
          final totalWidth = selectedBox.width;
          final totalHeight = selectedBox.height;
          state.fixedScaleCenter = Offset(
            selectedBox.x + totalWidth / 2,
            selectedBox.y + totalHeight / 2,
          );
          state.initialWidth = selectedBox.width;
          state.initialHeight = selectedBox.height;
          // 保存初始字体大小（仅文本类型）
          if (selectedBox.type == ElementType.text) {
            state.initialFontSize = selectedBox.fontSize;
          }
        }
      }
    } else {
      // 待定状态：可能是拖动，也可能是点击取消激活
      currentInteraction = 'pending_drag_or_tap';
      dragStartBoxPosition = selectedBox.position;
    }
  }

  /// 处理双指按下
  void _handleDoublePointerDown(List<CanvasElement> boxes, String selectedId) {
    if (selectedId.isEmpty) return;
    final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    final state = _stateForBox(selectedBox);

    currentInteraction = 'scale';
    lastScale = _computeScale();

    selectedBox.scale = 1.0;

    // 始终重新计算缩放中心点（基于当前文本框的中心）
    final totalWidth = selectedBox.width;
    final totalHeight = selectedBox.height;
    state.fixedScaleCenter = Offset(
      selectedBox.x + totalWidth / 2,
      selectedBox.y + totalHeight / 2,
    );
    state.initialWidth = selectedBox.width;
    state.initialHeight = selectedBox.height;
    // 保存初始字体大小（仅文本类型）
    if (selectedBox.type == ElementType.text) {
      state.initialFontSize = selectedBox.fontSize;
    }

    // 保存操作开始时的状态
    _operationStartCumulativeScale = selectedBox.scale;
    _operationStartWidth = selectedBox.width;
    _operationStartHeight = selectedBox.height;
    _operationStartPosition = Offset(selectedBox.x, selectedBox.y);
    if (selectedBox.type == ElementType.text) {
      _operationStartFontSize = selectedBox.fontSize;
    }

    debugPrint('双指缩放开始');
  }

  /// 处理指针移动事件
  bool handlePointerMove(
    PointerMoveEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    pointers[event.pointer] = event.localPosition;

    if (pointers.length == 1) {
      // 单指移动：如果之前是缩放状态，应该先重置状态
      if (currentInteraction == 'scale') {
        _resetDragState();
        currentInteraction = null;
        debugPrint('⚠️ 单指移动时检测到残留的缩放状态，已重置');
        return false;
      }
      return _handleSinglePointerMove(event, boxes, selectedId);
    } else if (pointers.length == 2) {
      // 双指移动：只处理缩放状态
      if (currentInteraction == 'scale') {
        return _handleDoublePointerMove(boxes, selectedId);
      } else {
        // 如果双指移动但状态不是缩放，可能是从其他状态切换过来的，重置状态
        debugPrint('⚠️ 双指移动但交互状态不是 scale: $currentInteraction');
        _resetDragState();
        return false;
      }
    }
    return false;
  }

  /// 处理单指移动
  bool _handleSinglePointerMove(
    PointerMoveEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    // 如果没有当前交互，则不处理
    if (currentInteraction == null) {
      return false;
    }

    // 如果当前交互是缩放状态，不应该处理单指移动（防止从双指缩放切换到单指时误触发拖动）
    if (currentInteraction == 'scale') {
      return false;
    }

    // 检测移动距离（仅对待定状态）
    if (currentInteraction == 'pending_drag_or_tap' &&
        dragStartPosition != null) {
      // 确保 dragStartPosition 是有效的（使用 localPosition 进行比较）
      final delta = event.localPosition - dragStartPosition!;
      if (delta.distance > dragStartThreshold) {
        // 只有在 dragStartBoxPosition 也存在时才允许转为拖动
        if (dragStartBoxPosition != null) {
          hasMoved = true;
          currentInteraction = 'drag';
          debugPrint('✅ 移动超过阈值，从待定状态转为拖动');
        } else {
          // 如果 dragStartBoxPosition 不存在，说明状态不一致，重置状态
          debugPrint('⚠️ 状态不一致：dragStartBoxPosition 为空，重置拖动状态');
          _resetDragState();
          currentInteraction = null;
          return false;
        }
      } else {
        // 还在阈值内，不处理
        return false;
      }
    }

    // 如果还是待定状态，不处理移动
    if (currentInteraction == 'pending_drag_or_tap') {
      return false;
    }

    // 获取要操作的元素（可能是选中的，也可能是待选中的）
    if (selectedId.isEmpty) return false;

    // 元素被锁定后不能够操作
    final targetBox = boxes.firstWhere((box) => box.id == selectedId);
    if (targetBox.locked) {
      return false;
    }

    switch (currentInteraction) {
      case 'drag':
        // 严格检查拖动状态的有效性
        if (dragStartPosition != null && dragStartBoxPosition != null) {
          final delta = event.localPosition - dragStartPosition!;
          final position = dragStartBoxPosition! + delta;
          targetBox.x = position.dx;
          targetBox.y = position.dy;

          // 如果还没有保存初始位置，现在保存（首次移动时）
          _operationStartPosition ??= dragStartBoxPosition;
        } else {
          // 状态不一致，重置并停止拖动
          debugPrint(
            '⚠️ 拖动失败: dragStartPosition=$dragStartPosition, dragStartBoxPosition=$dragStartBoxPosition，重置状态',
          );
          _resetDragState();
          currentInteraction = null;
          return false;
        }
        break;
      case 'rotate':
        _updateRotation(targetBox, event.localPosition);
        // 移除频繁的调试打印，提升性能
        break;

      case 'resize':
        _updateResize(targetBox, event.localPosition);
        // 移除频繁的调试打印，提升性能
        break;
      default:
        return false;
    }

    return true;
  }

  /// 更新旋转
  void _updateRotation(CanvasElement box, Offset currentPosition) {
    final state = _stateForBox(box);
    if (state.rotateLastPosition == null) return;

    // 计算容器中心（外层容器包含边框）
    final totalWidth = box.width;
    final totalHeight = box.height;
    final globalContainerCenter = Offset(
      box.x + totalWidth / 2,
      box.y + totalHeight / 2,
    );

    final currentAngle = math.atan2(
      currentPosition.dy - globalContainerCenter.dy,
      currentPosition.dx - globalContainerCenter.dx,
    );
    final lastAngle = math.atan2(
      state.rotateLastPosition!.dy - globalContainerCenter.dy,
      state.rotateLastPosition!.dx - globalContainerCenter.dx,
    );

    double angleDelta = currentAngle - lastAngle;

    if (angleDelta > math.pi) {
      angleDelta -= 2 * math.pi;
    } else if (angleDelta < -math.pi) {
      angleDelta += 2 * math.pi;
    }

    box.rotation += angleDelta;
    state.rotateLastPosition = currentPosition;
  }

  /// 更新调整大小
  void _updateResize(CanvasElement box, Offset currentPosition) {
    final state = _stateForBox(box);
    if (state.resizingHandle == null ||
        state.resizeStartPosition == null ||
        state.resizeAnchorPoint == null) {
      return;
    }

    final delta = currentPosition - state.resizeStartPosition!;

    if (box.type == ElementType.line &&
        (state.resizingHandle! == 'top-left' ||
            state.resizingHandle! == 'top-right' ||
            state.resizingHandle! == 'bottom-right' ||
            state.resizingHandle! == 'bottom-left')) {
      return;
    }

    final cos = math.cos(-box.rotation);
    final sin = math.sin(-box.rotation);
    final adjustedDx = delta.dx * cos - delta.dy * sin;
    final adjustedDy = delta.dx * sin + delta.dy * cos;

    double newWidth = state.resizeStartWidth;
    double newHeight = state.resizeStartHeight;

    // 文本类型特殊处理
    if (box.type == ElementType.text) {
      final minTextSize = _calculateMinTextSize(box);
      final minWidth = minTextSize.width;
      final minHeight = minTextSize.height;

      switch (state.resizingHandle!) {
        case 'left':
        case 'right':
          if (state.resizingHandle! == 'right') {
            newWidth = (state.resizeStartWidth + adjustedDx).clamp(
              minWidth,
              maxSize,
            );
          } else {
            newWidth = (state.resizeStartWidth - adjustedDx).clamp(
              minWidth,
              maxSize,
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
          newHeight = textSize.height.clamp(minHeight, maxSize);
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

            final finalFontSize = math.max(scaledFontSize, minFontSize);
            final finalFontSpace = math.max(scaledFontSpace, 0.0);

            final finalWidth = (scaledFontSize >= minFontSize)
                ? scaledWidth
                : (state.resizeStartWidth *
                      (minFontSize / state.resizeStartFontSize));

            final textSize = TextMeasureUtil.measureTextWithWidth(
              text: box.text,
              fontSize: finalFontSize,
              fontFamily: box.fontFamily,
              fontWeight: box.fontWeight,
              letterSpacing: finalFontSpace,
              lineHeight: state.resizeStartLineHeight,
              maxWidth: finalWidth,
            );

            newWidth = math.max(finalWidth, 0.0).clamp(0.0, maxSize);
            newHeight = math.max(textSize.height, 0.0).clamp(0.0, maxSize);
            box.fontSize = finalFontSize.clamp(minFontSize, 200.0);
            box.fontSpace = finalFontSpace;
          } else {
            newWidth = (state.resizeStartWidth * scale).clamp(
              minWidth,
              maxSize,
            );
            newHeight = (newWidth / state.resizeAspectRatio).clamp(
              minHeight,
              maxSize,
            );
            newWidth = (newHeight * state.resizeAspectRatio).clamp(
              minWidth,
              maxSize,
            );
            final actualScale = newWidth / state.resizeStartWidth;
            box.fontSize = (state.resizeStartFontSize * actualScale).clamp(
              minFontSize,
              200.0,
            );
          }
          break;
        default:
          break;
      }
    } else {
      switch (state.resizingHandle!) {
        case 'top-left':
          final scaleX =
              (state.resizeStartWidth - adjustedDx) / state.resizeStartWidth;
          final scaleY =
              (state.resizeStartHeight - adjustedDy) / state.resizeStartHeight;
          final scale = (scaleX + scaleY) / 2;
          newWidth = (state.resizeStartWidth * scale).clamp(50.0, maxSize);
          newHeight = (newWidth / state.resizeAspectRatio).clamp(50.0, maxSize);
          newWidth = (newHeight * state.resizeAspectRatio).clamp(50.0, maxSize);
          break;
        case 'top':
          newHeight = (state.resizeStartHeight - adjustedDy).clamp(
            box.type == ElementType.line ? 20.0 : 50.0,
            maxSize,
          );
          break;
        case 'top-right':
          final scaleX =
              (state.resizeStartWidth + adjustedDx) / state.resizeStartWidth;
          final scaleY =
              (state.resizeStartHeight - adjustedDy) / state.resizeStartHeight;
          final scale = (scaleX + scaleY) / 2;
          newWidth = (state.resizeStartWidth * scale).clamp(50.0, maxSize);
          newHeight = (newWidth / state.resizeAspectRatio).clamp(50.0, maxSize);
          newWidth = (newHeight * state.resizeAspectRatio).clamp(50.0, maxSize);
          break;
        case 'right':
          newWidth = (state.resizeStartWidth + adjustedDx).clamp(50.0, maxSize);
          break;
        case 'bottom-right':
          final scaleX =
              (state.resizeStartWidth + adjustedDx) / state.resizeStartWidth;
          final scaleY =
              (state.resizeStartHeight + adjustedDy) / state.resizeStartHeight;
          final scale = (scaleX + scaleY) / 2;
          newWidth = (state.resizeStartWidth * scale).clamp(50.0, maxSize);
          newHeight = (newWidth / state.resizeAspectRatio).clamp(50.0, maxSize);
          newWidth = (newHeight * state.resizeAspectRatio).clamp(50.0, maxSize);
          break;
        case 'bottom':
          newHeight = (state.resizeStartHeight + adjustedDy).clamp(
            box.type == ElementType.line ? 20.0 : 50.0,
            maxSize,
          );
          break;
        case 'bottom-left':
          final scaleX =
              (state.resizeStartWidth - adjustedDx) / state.resizeStartWidth;
          final scaleY =
              (state.resizeStartHeight + adjustedDy) / state.resizeStartHeight;
          final scale = (scaleX + scaleY) / 2;
          newWidth = (state.resizeStartWidth * scale).clamp(50.0, maxSize);
          newHeight = (newWidth / state.resizeAspectRatio).clamp(50.0, maxSize);
          newWidth = (newHeight * state.resizeAspectRatio).clamp(50.0, maxSize);
          break;
        case 'left':
          newWidth = (state.resizeStartWidth - adjustedDx).clamp(50.0, maxSize);
          break;
      }
    }

    box.width = newWidth;
    box.height = newHeight;

    final totalNewWidth = box.width;
    final totalNewHeight = box.height;

    Offset newAnchorPointLocal = Offset.zero;
    switch (state.resizingHandle!) {
      case 'top-left':
        newAnchorPointLocal = Offset(totalNewWidth, totalNewHeight);
        break;
      case 'top':
        newAnchorPointLocal = Offset(totalNewWidth / 2, totalNewHeight);
        break;
      case 'top-right':
        newAnchorPointLocal = Offset(0, totalNewHeight);
        break;
      case 'right':
        newAnchorPointLocal = Offset(0, totalNewHeight / 2);
        break;
      case 'bottom-right':
        newAnchorPointLocal = Offset(0, 0);
        break;
      case 'bottom':
        newAnchorPointLocal = Offset(totalNewWidth / 2, 0);
        break;
      case 'bottom-left':
        newAnchorPointLocal = Offset(totalNewWidth, 0);
        break;
      case 'left':
        newAnchorPointLocal = Offset(totalNewWidth, totalNewHeight / 2);
        break;
    }

    final cosRot = math.cos(box.rotation);
    final sinRot = math.sin(box.rotation);
    final rotatedNewPoint = Offset(
      newAnchorPointLocal.dx * cosRot - newAnchorPointLocal.dy * sinRot,
      newAnchorPointLocal.dx * sinRot + newAnchorPointLocal.dy * cosRot,
    );

    Offset position = state.resizeAnchorPoint! - rotatedNewPoint;
    box.x = position.dx;
    box.y = position.dy;
  }

  /// 处理双指移动
  bool _handleDoublePointerMove(List<CanvasElement> boxes, String selectedId) {
    if (selectedId.isEmpty) return false;

    // 确保当前交互是缩放状态
    if (currentInteraction != 'scale') {
      debugPrint('⚠️ 双指移动时交互状态不是 scale: $currentInteraction');
      return false;
    }

    final currentScale = _computeScale();
    final scale = (currentScale / lastScale).clamp(0.5, 2.0);

    final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    final state = _stateForBox(selectedBox);
    if (selectedBox.locked) {
      return false;
    }

    selectedBox.scale *= scale;
    selectedBox.scale = selectedBox.scale.clamp(0.1, 10.0);

    lastScale = currentScale;
    hasMoved = true;

    // 双指缩放时，确保拖动相关状态被清除（防止误触发拖动）
    if (dragStartPosition != null || dragStartBoxPosition != null) {
      _resetDragState();
    }

    if (state.fixedScaleCenter != null) {
      // 对于文本类型，根据最小字体大小计算最小尺寸
      double minWidth = 50.0;
      double minHeight = 50.0;
      if (selectedBox.type == ElementType.text) {
        final minTextSize = _calculateMinTextSize(selectedBox);
        minWidth = minTextSize.width;
        minHeight = minTextSize.height;
      }

      final newWidth = (state.initialWidth * selectedBox.scale).clamp(
        minWidth,
        double.infinity,
      );
      final newHeight = (state.initialHeight * selectedBox.scale).clamp(
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

      selectedBox.x = newPosition.dx;
      selectedBox.y = newPosition.dy;

      selectedBox.width = newWidth;
      selectedBox.height = newHeight;

      // 如果是文本类型，同时缩放字体大小
      if (selectedBox.type == ElementType.text) {
        selectedBox.fontSize = (state.initialFontSize * selectedBox.scale)
            .clamp(minFontSize, double.infinity);
      }
      // 移除频繁的调试打印，提升性能
    }

    return true;
  }

  /// 处理指针抬起事件
  bool handlePointerUp(
    PointerUpEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    pointers.remove(event.pointer);

    if (pointers.isEmpty) {
      return _handleAllPointersUp(event, boxes, selectedId);
    } else if (pointers.length == 1) {
      // 从双指切换到单指时，完全重置所有状态，防止单指误触发拖动
      _resetDragState();
      lastScale = 1.0;
      currentInteraction = null;
      debugPrint('从双指切换到单指，已重置拖动状态');
    }

    return false;
  }

  /// 处理所有指针抬起
  bool _handleAllPointersUp(
    PointerUpEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    // 清理状态
    _cleanupInteraction(boxes, selectedId);

    return false;
  }

  /// 处理指针取消事件
  void handlePointerCancel(PointerCancelEvent event) {
    pointers.remove(event.pointer);
    if (pointers.isEmpty) {
      reset();
      debugPrint('指针事件取消，重置所有状态');
    }
  }

  /// 清理交互状态
  void _cleanupInteraction(List<CanvasElement> boxes, String selectedId) {
    // 在清理状态前，记录命令（如果操作有实际变化）
    if (selectedId.isNotEmpty && hasMoved && historyManager != null) {
      try {
        final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
        final currentPosition = Offset(selectedBox.x, selectedBox.y);

        switch (currentInteraction) {
          case 'drag':
            if (_operationStartPosition != null &&
                (_operationStartPosition!.dx != currentPosition.dx ||
                    _operationStartPosition!.dy != currentPosition.dy)) {
              historyManager!.executeCommand(
                MoveElementCommand(
                  boxes,
                  selectedId,
                  _operationStartPosition!,
                  currentPosition,
                ),
              );
            }
            break;

          case 'rotate':
            if (_operationStartRotation != null &&
                _operationStartRotation != selectedBox.rotation) {
              historyManager!.executeCommand(
                RotateElementCommand(
                  boxes,
                  selectedId,
                  _operationStartRotation!,
                  selectedBox.rotation,
                ),
              );
            }
            break;

          case 'resize':
            if (_operationStartWidth != null &&
                _operationStartHeight != null &&
                _operationStartPosition != null &&
                (_operationStartWidth != selectedBox.width ||
                    _operationStartHeight != selectedBox.height ||
                    _operationStartPosition!.dx != currentPosition.dx ||
                    _operationStartPosition!.dy != currentPosition.dy)) {
              historyManager!.executeCommand(
                ResizeElementCommand(
                  boxes: boxes,
                  elementId: selectedId,
                  oldWidth: _operationStartWidth!,
                  oldHeight: _operationStartHeight!,
                  oldPosition: _operationStartPosition!,
                  newWidth: selectedBox.width,
                  newHeight: selectedBox.height,
                  newPosition: currentPosition,
                  oldFontSize: _operationStartFontSize,
                  newFontSize: selectedBox.type == ElementType.text
                      ? selectedBox.fontSize
                      : null,
                  oldFontSpace: _operationStartFontSpace,
                  newFontSpace: selectedBox.type == ElementType.text
                      ? selectedBox.fontSpace
                      : null,
                ),
              );
            }
            break;

          case 'scale':
            if (_operationStartCumulativeScale != null &&
                _operationStartWidth != null &&
                _operationStartHeight != null &&
                _operationStartPosition != null &&
                (_operationStartCumulativeScale != selectedBox.scale ||
                    _operationStartWidth != selectedBox.width ||
                    _operationStartHeight != selectedBox.height ||
                    _operationStartPosition!.dx != currentPosition.dx ||
                    _operationStartPosition!.dy != currentPosition.dy)) {
              historyManager!.executeCommand(
                ScaleElementCommand(
                  boxes: boxes,
                  elementId: selectedId,
                  oldCumulativeScale: _operationStartCumulativeScale!,
                  newCumulativeScale: selectedBox.scale,
                  oldWidth: _operationStartWidth!,
                  oldHeight: _operationStartHeight!,
                  oldPosition: _operationStartPosition!,
                  newWidth: selectedBox.width,
                  newHeight: selectedBox.height,
                  newPosition: currentPosition,
                  oldFontSize: _operationStartFontSize,
                  newFontSize: selectedBox.type == ElementType.text
                      ? selectedBox.fontSize
                      : null,
                ),
              );
            }
            break;
        }
      } catch (e) {
        debugPrint('记录命令时出错: $e');
      }
    }

    if (currentInteraction == 'resize' && selectedId.isNotEmpty) {
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      final state = _stateForBox(selectedBox);
      state.resizingHandle = null;
      state.resizeStartPosition = null;
      state.resizeAnchorPoint = null;
      debugPrint('调整大小结束');
    }

    if (currentInteraction == 'rotate' && selectedId.isNotEmpty) {
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      final state = _stateForBox(selectedBox);
      state.rotateLastPosition = null;
      debugPrint('旋转结束');
    }

    reset();
    debugPrint('指针抬起，重置状态');
  }

  /// 重置拖动相关状态（用于从双指切换到单指等场景）
  void _resetDragState() {
    hasMoved = false;
    dragStartPosition = null;
    dragStartBoxPosition = null;
  }

  /// 重置所有状态
  void reset() {
    currentInteraction = null;
    _resetDragState();
    lastScale = 1.0;
    // 清除操作开始时的状态快照
    _operationStartPosition = null;
    _operationStartRotation = null;
    _operationStartWidth = null;
    _operationStartHeight = null;
    _operationStartCumulativeScale = null;
    _operationStartFontSize = null;
    _operationStartFontSpace = null;
  }

  /// 开始调整大小
  void _startResize(CanvasElement box, String handle, Offset position) {
    final state = _stateForBox(box);
    state.resizingHandle = handle;
    state.resizeStartWidth = box.width;
    state.resizeStartHeight = box.height;
    state.resizeAspectRatio = box.width / box.height; // 保存宽高比
    state.resizeStartPosition = position;
    // 保存初始字体大小、行高、字间距（仅文本类型）
    if (box.type == ElementType.text) {
      state.resizeStartFontSize = box.fontSize;
      state.resizeStartLineHeight = box.lineHeight;
      state.resizeStartFontSpace = box.fontSpace;
    }

    // 计算外层容器总尺寸（包含边框）
    final totalStartWidth = box.width;
    final totalStartHeight = box.height;

    Offset anchorPointLocal = Offset.zero;
    switch (handle) {
      case 'top-left':
        // 锚点是右下角（相对于外层容器）
        anchorPointLocal = Offset(totalStartWidth, totalStartHeight);
        break;
      case 'top':
        // 锚点是下边中点
        anchorPointLocal = Offset(totalStartWidth / 2, totalStartHeight);
        break;
      case 'top-right':
        // 锚点是左下角
        anchorPointLocal = Offset(0, totalStartHeight);
        break;
      case 'right':
        // 锚点是左边中点
        anchorPointLocal = Offset(0, totalStartHeight / 2);
        break;
      case 'bottom-right':
        // 锚点是左上角
        anchorPointLocal = Offset(0, 0);
        break;
      case 'bottom':
        // 锚点是上边中点
        anchorPointLocal = Offset(totalStartWidth / 2, 0);
        break;
      case 'bottom-left':
        // 锚点是右上角
        anchorPointLocal = Offset(totalStartWidth, 0);
        break;
      case 'left':
        // 锚点是右边中点
        anchorPointLocal = Offset(totalStartWidth, totalStartHeight / 2);
        break;
    }

    final cos = math.cos(box.rotation);
    final sin = math.sin(box.rotation);
    final rotatedPoint = Offset(
      anchorPointLocal.dx * cos - anchorPointLocal.dy * sin,
      anchorPointLocal.dx * sin + anchorPointLocal.dy * cos,
    );

    // 锚点是全局坐标（相对于画布）
    state.resizeAnchorPoint = box.position + rotatedPoint;
  }

  /// 计算两个指针之间的距离
  double _computeScale() {
    if (pointers.length < 2) return 1.0;

    final positions = pointers.values.toList();
    final dx = positions[0].dx - positions[1].dx;
    final dy = positions[0].dy - positions[1].dy;
    return (dx * dx + dy * dy).abs();
  }

  /// 根据最小字体大小计算文本框的最小尺寸
  /// [box] 文本框数据
  /// 返回最小宽度和最小高度
  Size _calculateMinTextSize(CanvasElement box) {
    // 如果没有文本，返回默认最小值
    if (box.text.isEmpty) {
      return Size(minBoxSize, minBoxSize);
    }

    // 使用最小字体大小计算文本的最小尺寸
    // 先计算单行时的最小宽度
    final singleLineSize = TextMeasureUtil.measureText(
      text: box.text,
      fontSize: minFontSize,
      fontFamily: box.fontFamily,
      fontWeight: box.fontWeight,
      letterSpacing: box.fontSpace,
      lineHeight: box.lineHeight,
    );

    // 如果单行宽度太小，使用默认最小值
    if (singleLineSize.width < minBoxSize) {
      return Size(
        minBoxSize,
        minBoxSize > singleLineSize.height ? minBoxSize : singleLineSize.height,
      );
    }

    // 使用当前文本框宽度（或单行宽度，取较小值）来计算多行文本的高度
    final maxWidth = math.min(box.width, singleLineSize.width);
    final minTextSize = TextMeasureUtil.measureTextWithWidth(
      text: box.text,
      fontSize: minFontSize,
      fontFamily: box.fontFamily,
      fontWeight: box.fontWeight,
      letterSpacing: box.fontSpace,
      lineHeight: box.lineHeight,
      maxWidth: maxWidth,
    );

    // 确保最小尺寸不小于默认值
    return Size(
      math.max(minBoxSize, minTextSize.width),
      math.max(minBoxSize, minTextSize.height),
    );
  }
}
