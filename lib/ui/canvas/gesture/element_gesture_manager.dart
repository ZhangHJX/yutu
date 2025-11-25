import 'package:flutter/material.dart';
import '../utils/text_measure_util.dart';
import '../history/canvas_history_manager.dart';
import 'element_extension/element_interaction_state.dart';
import '../model/index.dart';
import 'dart:math' as math;

part 'element_extension/element_gesture_session.dart';
part 'element_extension/element_gesture_manager_image.dart';
part 'element_extension/element_gesture_manager_shape.dart';
part 'element_extension/element_gesture_manager_text.dart';

/// 画布手势管理器： 负责处理所有的手势交互逻辑
class ElementGestureManager {
  final _GestureSession _session = _GestureSession();
  CanvasHistoryManager? historyManager;
  static const double dragStartThreshold = 5.0; // 开始拖动的距离阈值

  // 每个元素的交互状态缓存
  final Map<String, ElementInteractionState> _interactionStates = {};
  ElementInteractionState _stateForBox(CanvasElement box) {
    return _interactionStates.putIfAbsent(
      box.id,
      () => ElementInteractionState(),
    );
  }

  _OperationSnapshot get _snapshot => _session.snapshot;

  void _captureSnapshot(
    CanvasElement box, {
    bool position = false,
    bool size = false,
    bool rotation = false,
    bool cumulativeScale = false,
    bool fontSize = false,
    bool fontSpace = false,
  }) {
    if (position) {
      _snapshot.position = Offset(box.x, box.y);
    }
    if (size) {
      _snapshot.width = box.width;
      _snapshot.height = box.height;
    }
    if (rotation) {
      _snapshot.rotation = box.rotation;
    }
    if (cumulativeScale) {
      _snapshot.cumulativeScale = box.scale;
    }
    if (fontSize) {
      _snapshot.fontSize = box.fontSize;
    }
    if (fontSpace) {
      _snapshot.fontSpace = box.fontSpace;
    }
  }

  bool _positionChanged(CanvasElement box) {
    final start = _snapshot.position;
    if (start == null) return false;
    return start.dx != box.x || start.dy != box.y;
  }

  bool _rotationChanged(CanvasElement box) {
    final start = _snapshot.rotation;
    if (start == null) return false;
    return (start - box.rotation).abs() > 0.0001;
  }

  bool _sizeChanged(CanvasElement box) {
    final startWidth = _snapshot.width;
    final startHeight = _snapshot.height;
    if (startWidth == null || startHeight == null) return false;
    return startWidth != box.width || startHeight != box.height;
  }

  bool _scaleChanged(CanvasElement box) {
    final startScale = _snapshot.cumulativeScale;
    if (startScale == null) return false;
    if ((startScale - box.scale).abs() > 0.0001) {
      return true;
    }
    return _sizeChanged(box) || _positionChanged(box);
  }

  void _preparePendingDrag(
    CanvasElement selectedBox,
    ElementInteractionState state,
  ) {
    _session.beginMode(_InteractionMode.pendingDragOrTap);
    _session.dragStartElementPosition = selectedBox.position;
    _captureSnapshot(selectedBox, position: true);

    if (state.fixedScaleCenter == null) {
      final totalWidth = selectedBox.width;
      final totalHeight = selectedBox.height;
      state.fixedScaleCenter = Offset(
        selectedBox.x + totalWidth / 2,
        selectedBox.y + totalHeight / 2,
      );
      state.initialWidth = selectedBox.width;
      state.initialHeight = selectedBox.height;
      if (selectedBox.type == ElementType.text) {
        state.initialFontSize = selectedBox.fontSize;
      }
    }
  }

  void clearInteractionState(String elementId) {
    _interactionStates.remove(elementId);
  }

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
    _session.updatePointer(event.pointer, event.localPosition);

    if (_session.pointers.length == 1) {
      // 单指按下：如果之前有残留状态，先清理
      if (_session.isScaling) {
        _resetDragState();
        _session.beginMode(_InteractionMode.idle);
        debugPrint('⚠️ 单指按下时检测到残留的缩放状态，已重置');
      }
      _handleSinglePointerDown(event, boxes, selectedId);
    } else if (_session.pointers.length == 2) {
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
    if (_session.isScaling) {
      _resetDragState();
      _session.beginMode(_InteractionMode.idle);
      debugPrint('⚠️ 单指按下时检测到残留的缩放状态，已重置');
    }

    // 重置拖动状态并设置新的起始位置
    _session.dragStartPointer = event.localPosition;

    CanvasElement selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    final state = _stateForBox(selectedBox);
    final hitTarget = MatrixUtilsXGesture.detectHitTarget(
      event.position,
      selectedBox,
      canvasMatrix,
    );

    if (hitTarget != null) {
      if (selectedBox.locked) {
        return;
      }

      if (hitTarget == 'rotate') {
        _session.beginMode(_InteractionMode.rotate);
        _session.markMoved();
        state.rotateLastPosition = event.localPosition;
        _captureSnapshot(selectedBox, rotation: true);
        debugPrint('✅ 判定为旋转: $selectedId');
        return;
      } else if (hitTarget.startsWith('resize:')) {
        final handle = hitTarget.substring(7);
        _session.beginMode(_InteractionMode.resize);
        _session.markMoved();
        _captureSnapshot(
          selectedBox,
          size: true,
          position: true,
          fontSize: selectedBox.type == ElementType.text,
          fontSpace: selectedBox.type == ElementType.text,
        );
        _startResize(selectedBox, handle, event.localPosition);
        debugPrint('✅ 判定为缩放: $selectedId, 控制点: $handle');
        return;
      } else if (hitTarget == 'content') {
        _preparePendingDrag(selectedBox, state);
      }
    } else {
      _preparePendingDrag(selectedBox, state);
    }
  }

  /// 处理双指按下
  void _handleDoublePointerDown(List<CanvasElement> boxes, String selectedId) {
    if (selectedId.isEmpty) return;
    final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    final state = _stateForBox(selectedBox);

    _session.beginMode(_InteractionMode.scale);
    _session.lastScaleDistance = _computeScale();

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

    _captureSnapshot(
      selectedBox,
      cumulativeScale: true,
      size: true,
      position: true,
      fontSize: selectedBox.type == ElementType.text,
    );

    debugPrint('双指缩放开始');
  }

  /// 处理指针移动事件
  bool handlePointerMove(
    PointerMoveEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    _session.updatePointer(event.pointer, event.localPosition);

    if (_session.pointers.length == 1) {
      // 单指移动：如果之前是缩放状态，应该先重置状态
      if (_session.isScaling) {
        _resetDragState();
        _session.beginMode(_InteractionMode.idle);
        debugPrint('⚠️ 单指移动时检测到残留的缩放状态，已重置');
        return false;
      }
      return _handleSinglePointerMove(event, boxes, selectedId);
    } else if (_session.pointers.length == 2) {
      // 双指移动：只处理缩放状态
      if (_session.isScaling) {
        return _handleDoublePointerMove(boxes, selectedId);
      } else {
        // 如果双指移动但状态不是缩放，可能是从其他状态切换过来的，重置状态
        debugPrint('⚠️ 双指移动但交互状态不是 scale: ${_session.mode}');
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
    if (!_session.isActive || _session.isScaling) {
      return false;
    }

    if (_session.isPendingDrag && _session.dragStartPointer != null) {
      final delta = event.localPosition - _session.dragStartPointer!;
      if (delta.distance > dragStartThreshold) {
        if (_session.dragStartElementPosition != null) {
          _session.beginMode(_InteractionMode.drag);
          _session.dragStartPointer = event.localPosition;
          _session.markMoved();
          debugPrint('✅ 移动超过阈值，从待定状态转为拖动');
        } else {
          debugPrint('⚠️ 状态不一致：dragStartElementPosition 为空，重置拖动状态');
          _resetDragState();
          _session.beginMode(_InteractionMode.idle);
          return false;
        }
      } else {
        return false;
      }
    }

    if (_session.isPendingDrag) {
      return false;
    }

    if (selectedId.isEmpty) return false;
    final targetBox = boxes.firstWhere((box) => box.id == selectedId);
    if (targetBox.locked) {
      return false;
    }

    switch (_session.mode) {
      case _InteractionMode.drag:
        if (_session.dragStartPointer != null &&
            _session.dragStartElementPosition != null) {
          final delta = event.localPosition - _session.dragStartPointer!;
          final position = _session.dragStartElementPosition! + delta;
          targetBox.x = position.dx;
          targetBox.y = position.dy;
        } else {
          debugPrint(
            '⚠️ 拖动失败: dragStartPointer=${_session.dragStartPointer}, dragStartElementPosition=${_session.dragStartElementPosition}，重置状态',
          );
          _resetDragState();
          _session.beginMode(_InteractionMode.idle);
          return false;
        }
        break;
      case _InteractionMode.rotate:
        _updateRotation(targetBox, event.localPosition);
        break;
      case _InteractionMode.resize:
        _updateResize(targetBox, event.localPosition);
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

    final cos = math.cos(-box.rotation);
    final sin = math.sin(-box.rotation);
    final adjustedDx = delta.dx * cos - delta.dy * sin;
    final adjustedDy = delta.dx * sin + delta.dy * cos;

    // 不同类型的元素使用各自的尺寸计算逻辑
    Size newSize;
    switch (box.type) {
      case ElementType.text:
        newSize = _updateResizeForText(box, state, adjustedDx, adjustedDy);
        break;
      case ElementType.image:
        newSize = _updateResizeForImage(box, state, adjustedDx, adjustedDy);
        break;
      case ElementType.rectangle:
      case ElementType.ellipse:
      case ElementType.line:
        newSize = _updateResizeForShape(box, state, adjustedDx, adjustedDy);
        break;
    }

    box.width = newSize.width;
    box.height = newSize.height;

    final totalNewWidth = box.width;
    final totalNewHeight = box.height;
    final newAnchorPointLocal = _anchorLocalForHandle(
      state.resizingHandle!,
      totalNewWidth,
      totalNewHeight,
    );
    final newTopLeft = _topLeftFromAnchor(
      anchorWorld: state.resizeAnchorPoint!,
      width: totalNewWidth,
      height: totalNewHeight,
      rotation: box.rotation,
      anchorLocal: newAnchorPointLocal,
    );
    box.x = newTopLeft.dx;
    box.y = newTopLeft.dy;
  }

  /// 处理双指移动
  bool _handleDoublePointerMove(List<CanvasElement> boxes, String selectedId) {
    if (selectedId.isEmpty) return false;

    if (!_session.isScaling) {
      debugPrint('⚠️ 双指移动时交互状态不是 scale: ${_session.mode}');
      return false;
    }

    final currentScale = _computeScale();
    final scale = (currentScale / _session.lastScaleDistance).clamp(0.5, 2.0);

    final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    final state = _stateForBox(selectedBox);
    if (selectedBox.locked) {
      return false;
    }

    selectedBox.scale *= scale;
    selectedBox.scale = selectedBox.scale.clamp(0.1, 10.0);

    _session.lastScaleDistance = currentScale;
    _session.markMoved();

    if (_session.dragStartPointer != null ||
        _session.dragStartElementPosition != null) {
      _resetDragState();
    }

    if (state.fixedScaleCenter != null) {
      switch (selectedBox.type) {
        case ElementType.text:
          _applyScaleForText(selectedBox, state);
          break;
        case ElementType.image:
          _applyScaleForImage(selectedBox, state);
          break;
        case ElementType.rectangle:
        case ElementType.ellipse:
        case ElementType.line:
          _applyScaleForShape(selectedBox, state);
          break;
      }
    }

    return true;
  }

  /// 处理指针抬起事件
  bool handlePointerUp(
    PointerUpEvent event,
    List<CanvasElement> boxes,
    String selectedId,
  ) {
    _session.removePointer(event.pointer);

    if (_session.pointers.isEmpty) {
      return _handleAllPointersUp(event, boxes, selectedId);
    } else if (_session.pointers.length == 1) {
      // 从双指切换到单指时，完全重置所有状态，防止单指误触发拖动
      _resetDragState();
      _session.lastScaleDistance = 1.0;
      _session.beginMode(_InteractionMode.idle);
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
    _session.removePointer(event.pointer);
    if (_session.pointers.isNotEmpty) {
      _session.resetPointers();
    }
    reset();
    debugPrint('指针事件取消，重置所有状态');
  }

  /// 清理交互状态
  void _cleanupInteraction(List<CanvasElement> boxes, String selectedId) {
    final completedMode = _session.mode;
    if (selectedId.isNotEmpty && _session.hasMoved && historyManager != null) {
      try {
        final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
        final currentPosition = Offset(selectedBox.x, selectedBox.y);

        switch (completedMode) {
          case _InteractionMode.drag:
            if (_snapshot.position != null && _positionChanged(selectedBox)) {
              historyManager!.executeCommand(
                MoveElementCommand(
                  boxes,
                  selectedId,
                  _snapshot.position!,
                  currentPosition,
                ),
              );
            }
            break;

          case _InteractionMode.rotate:
            if (_snapshot.rotation != null && _rotationChanged(selectedBox)) {
              historyManager!.executeCommand(
                RotateElementCommand(
                  boxes,
                  selectedId,
                  _snapshot.rotation!,
                  selectedBox.rotation,
                ),
              );
            }
            break;

          case _InteractionMode.resize:
            if (_snapshot.width != null &&
                _snapshot.height != null &&
                (_sizeChanged(selectedBox) || _positionChanged(selectedBox))) {
              historyManager!.executeCommand(
                ResizeElementCommand(
                  boxes: boxes,
                  elementId: selectedId,
                  oldWidth: _snapshot.width!,
                  oldHeight: _snapshot.height!,
                  oldPosition: _snapshot.position ?? currentPosition,
                  newWidth: selectedBox.width,
                  newHeight: selectedBox.height,
                  newPosition: currentPosition,
                  oldFontSize: _snapshot.fontSize,
                  newFontSize: selectedBox.type == ElementType.text
                      ? selectedBox.fontSize
                      : null,
                  oldFontSpace: _snapshot.fontSpace,
                  newFontSpace: selectedBox.type == ElementType.text
                      ? selectedBox.fontSpace
                      : null,
                ),
              );
            }
            break;

          case _InteractionMode.scale:
            if (_snapshot.cumulativeScale != null &&
                _scaleChanged(selectedBox)) {
              historyManager!.executeCommand(
                ScaleElementCommand(
                  boxes: boxes,
                  elementId: selectedId,
                  oldCumulativeScale: _snapshot.cumulativeScale!,
                  newCumulativeScale: selectedBox.scale,
                  oldWidth: _snapshot.width ?? selectedBox.width,
                  oldHeight: _snapshot.height ?? selectedBox.height,
                  oldPosition: _snapshot.position ?? currentPosition,
                  newWidth: selectedBox.width,
                  newHeight: selectedBox.height,
                  newPosition: currentPosition,
                  oldFontSize: _snapshot.fontSize,
                  newFontSize: selectedBox.type == ElementType.text
                      ? selectedBox.fontSize
                      : null,
                ),
              );
            }
            break;

          default:
            break;
        }
      } catch (e) {
        debugPrint('记录命令时出错: $e');
      }
    }

    if (completedMode == _InteractionMode.resize && selectedId.isNotEmpty) {
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      final state = _stateForBox(selectedBox);
      state.resizingHandle = null;
      state.resizeStartPosition = null;
      state.resizeAnchorPoint = null;
      debugPrint('调整大小结束');
    }

    if (completedMode == _InteractionMode.rotate && selectedId.isNotEmpty) {
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
    _session.dragStartPointer = null;
    _session.dragStartElementPosition = null;
  }

  /// 重置所有状态
  void reset() {
    _resetDragState();
    _session.resetPointers();
    _session.reset();
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

    final anchorPointLocal = _anchorLocalForHandle(
      handle,
      totalStartWidth,
      totalStartHeight,
    );
    state.resizeAnchorPoint = _localToWorld(
      width: totalStartWidth,
      height: totalStartHeight,
      rotation: box.rotation,
      topLeft: box.position,
      localPoint: anchorPointLocal,
    );
  }

  /// 计算两个指针之间的距离
  double _computeScale() {
    if (_session.pointers.length < 2) return 1.0;

    final positions = _session.pointers.values.toList();
    final dx = positions[0].dx - positions[1].dx;
    final dy = positions[0].dy - positions[1].dy;
    return (dx * dx + dy * dy).abs();
  }

  Offset _anchorLocalForHandle(String handle, double width, double height) {
    switch (handle) {
      case 'top-left':
        return Offset(width, height);
      case 'top':
        return Offset(width / 2, height);
      case 'top-right':
        return Offset(0, height);
      case 'right':
        return Offset(0, height / 2);
      case 'bottom-right':
        return Offset(0, 0);
      case 'bottom':
        return Offset(width / 2, 0);
      case 'bottom-left':
        return Offset(width, 0);
      case 'left':
      default:
        return Offset(width, height / 2);
    }
  }

  Offset _localToWorld({
    required double width,
    required double height,
    required double rotation,
    required Offset topLeft,
    required Offset localPoint,
  }) {
    final center = Offset(width / 2, height / 2);
    final translated = localPoint - center;
    final cosRot = math.cos(rotation);
    final sinRot = math.sin(rotation);
    final rotated = Offset(
      translated.dx * cosRot - translated.dy * sinRot,
      translated.dx * sinRot + translated.dy * cosRot,
    );
    return topLeft + center + rotated;
  }

  Offset _topLeftFromAnchor({
    required Offset anchorWorld,
    required double width,
    required double height,
    required double rotation,
    required Offset anchorLocal,
  }) {
    final center = Offset(width / 2, height / 2);
    final translated = anchorLocal - center;
    final cosRot = math.cos(rotation);
    final sinRot = math.sin(rotation);
    final rotated = Offset(
      translated.dx * cosRot - translated.dy * sinRot,
      translated.dx * sinRot + translated.dy * cosRot,
    );
    return anchorWorld - center - rotated;
  }
}
