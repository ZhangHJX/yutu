import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/create_design_model.dart';
import 'edit_content_box.dart';

/// 画布手势管理器
/// 负责处理所有的手势交互逻辑
class CanvasGestureManager {
  // 交互状态
  String?
  currentInteraction; // 'drag', 'rotate', 'resize', 'scale', 'pending_drag_or_tap', 'activate'

  bool hasMoved = false;
  String? pendingClickBoxId; // 待激活或取消激活的元素ID
  static const double dragStartThreshold = 5.0; // 开始拖动的距离阈值

  // 拖动相关
  Offset? dragStartPosition;
  Offset? dragStartBoxPosition;

  // 缩放相关
  final Map<int, Offset> pointers = {};
  double lastScale = 1.0;

  // 尺寸限制
  static const double maxSize = 1000000.0;

  /// 处理指针按下事件
  void handlePointerDown(
    PointerDownEvent event,
    List<EditBoxData> boxes,
    String selectedId,
    Function(String?) onSelect,
  ) {
    pointers[event.pointer] = event.localPosition;

    if (pointers.length == 1) {
      _handleSinglePointerDown(event, boxes, selectedId, onSelect);
    } else if (pointers.length == 2) {
      _handleDoublePointerDown(boxes, selectedId);
    }
  }

  /// 处理单指按下
  void _handleSinglePointerDown(
    PointerDownEvent event,
    List<EditBoxData> boxes,
    String selectedId,
    Function(String?) onSelect,
  ) {
    hasMoved = false;
    dragStartPosition = event.localPosition;
    pendingClickBoxId = null;

    EditBoxData? selectedBox;

    // 先检查当前选中的元素
    if (selectedId.isNotEmpty) {
      selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      final hitTarget = _detectHitTarget(event.localPosition, selectedBox);

      if (hitTarget != null) {
        if (hitTarget == 'rotate') {
          // 开始旋转
          currentInteraction = 'rotate';
          hasMoved = true; // 判定为旋转操作
          selectedBox.rotateLastPosition = event.localPosition;
          debugPrint('✅ 判定为旋转: $selectedId');
          return;
        } else if (hitTarget.startsWith('resize:')) {
          // 开始调整大小
          final handle = hitTarget.substring(7);
          currentInteraction = 'resize';
          hasMoved = true; // 判定为缩放操作
          _startResize(selectedBox, handle, event.localPosition);
          debugPrint('✅ 判定为缩放: $selectedId, 控制点: $handle');
          return;
        } else if (hitTarget == 'content') {
          // 待定状态：可能是拖动，也可能是点击取消激活
          currentInteraction = 'pending_drag_or_tap';
          pendingClickBoxId = selectedId; // 保存可能要取消激活的元素ID
          dragStartBoxPosition = selectedBox.position;
          // 初始化缩放中心点
          if (selectedBox.fixedScaleCenter == null) {
            selectedBox.fixedScaleCenter = Offset(
              selectedBox.position.dx + selectedBox.width / 2,
              selectedBox.position.dy + selectedBox.height / 2,
            );
            selectedBox.initialWidth = selectedBox.width;
            selectedBox.initialHeight = selectedBox.height;
          }

          debugPrint('✅ 待定状态: 可能拖动或点击取消激活 $selectedId');
          return;
        }
      }
      // 点击在选中元素外部，检查是否点击了其他元素
    } else {
      // 检查所有元素（从后往前，优先检查上层元素）
      for (int i = boxes.length - 1; i >= 0; i--) {
        final box = boxes[i];
        // 跳过已选中的元素（已经在上面处理过了）
        if (box.id == selectedId) continue;

        final hitTarget = _detectHitTarget(event.localPosition, box);
        if (hitTarget == 'content') {
          // 点击了未选中的元素，立即激活它（不能拖动）
          currentInteraction = 'activate';
          pendingClickBoxId = box.id; // 保存要激活的元素ID
          // 立即激活，不等待抬起事件
          onSelect(box.id);
          debugPrint('✅ 立即激活未选中元素: ${box.id}');
          return;
        }
      }
    }
  }

  /// 处理双指按下
  void _handleDoublePointerDown(List<EditBoxData> boxes, String selectedId) {
    if (selectedId.isEmpty) return;

    currentInteraction = 'scale';
    lastScale = _computeScale();

    final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
    selectedBox.cumulativeScale = 1.0;

    if (selectedBox.fixedScaleCenter == null) {
      selectedBox.fixedScaleCenter = Offset(
        selectedBox.position.dx + selectedBox.width / 2,
        selectedBox.position.dy + selectedBox.height / 2,
      );
      selectedBox.initialWidth = selectedBox.width;
      selectedBox.initialHeight = selectedBox.height;
    }

    debugPrint('双指缩放开始');
  }

  /// 处理指针移动事件
  bool handlePointerMove(
    PointerMoveEvent event,
    List<EditBoxData> boxes,
    String selectedId,
  ) {
    pointers[event.pointer] = event.localPosition;

    if (pointers.length == 1) {
      return _handleSinglePointerMove(event, boxes, selectedId);
    } else if (pointers.length == 2 && currentInteraction == 'scale') {
      return _handleDoublePointerMove(boxes, selectedId);
    }

    return false;
  }

  /// 处理单指移动
  bool _handleSinglePointerMove(
    PointerMoveEvent event,
    List<EditBoxData> boxes,
    String selectedId,
  ) {
    // 如果是激活操作，立即返回，不处理任何移动
    if (currentInteraction == 'activate') {
      return false;
    }

    // 如果没有当前交互，则不处理
    if (currentInteraction == null) {
      return false;
    }

    // 检测移动距离（仅对待定状态）
    if (currentInteraction == 'pending_drag_or_tap' &&
        dragStartPosition != null) {
      final delta = event.localPosition - dragStartPosition!;
      if (delta.distance > dragStartThreshold) {
        hasMoved = true;
        currentInteraction = 'drag';
        debugPrint('✅ 移动超过阈值，从待定状态转为拖动');
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
    final boxId = pendingClickBoxId ?? selectedId;
    if (boxId.isEmpty) return false;

    final targetBox = boxes.firstWhere((box) => box.id == boxId);

    switch (currentInteraction) {
      case 'drag':
        if (dragStartPosition != null && dragStartBoxPosition != null) {
          final delta = event.localPosition - dragStartPosition!;
          targetBox.position = dragStartBoxPosition! + delta;
          // 移除频繁的调试打印，提升性能
        } else {
          debugPrint(
            '⚠️ 拖动失败: dragStartPosition=$dragStartPosition, dragStartBoxPosition=$dragStartBoxPosition',
          );
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

  /// 处理双指移动
  bool _handleDoublePointerMove(List<EditBoxData> boxes, String selectedId) {
    if (selectedId.isEmpty) return false;

    final currentScale = _computeScale();
    final scale = (currentScale / lastScale).clamp(0.5, 2.0);

    final selectedBox = boxes.firstWhere((box) => box.id == selectedId);

    selectedBox.cumulativeScale *= scale;
    selectedBox.cumulativeScale = selectedBox.cumulativeScale.clamp(0.1, 10.0);

    lastScale = currentScale;
    hasMoved = true;

    if (selectedBox.fixedScaleCenter != null) {
      final newWidth = (selectedBox.initialWidth * selectedBox.cumulativeScale)
          .clamp(50.0, 1000.0);
      final newHeight =
          (selectedBox.initialHeight * selectedBox.cumulativeScale).clamp(
            50.0,
            1000.0,
          );

      final newPosition = Offset(
        selectedBox.fixedScaleCenter!.dx - newWidth / 2,
        selectedBox.fixedScaleCenter!.dy - newHeight / 2,
      );

      selectedBox.position = newPosition;
      selectedBox.width = newWidth;
      selectedBox.height = newHeight;
      // 移除频繁的调试打印，提升性能
    }

    return true;
  }

  /// 处理指针抬起事件
  bool handlePointerUp(
    PointerUpEvent event,
    List<EditBoxData> boxes,
    String selectedId,
    Function(String?) onSelect,
  ) {
    pointers.remove(event.pointer);

    if (pointers.isEmpty) {
      return _handleAllPointersUp(event, boxes, selectedId, onSelect);
    } else if (pointers.length == 1) {
      lastScale = 1.0;
      currentInteraction = null;
      debugPrint('从双指切换到单指');
    }

    return false;
  }

  /// 处理所有指针抬起
  bool _handleAllPointersUp(
    PointerUpEvent event,
    List<EditBoxData> boxes,
    String selectedId,
    Function(String?) onSelect,
  ) {
    // 如果是点击背景操作，执行取消选中
    if (currentInteraction == 'drag' && !hasMoved) {
      onSelect(null);
      debugPrint('✅ 点击背景，取消激活');
    }

    // 如果是激活操作，已经在按下时激活了，这里不需要再处理
    // 如果是待定状态（没有移动），判定为点击取消激活
    if (currentInteraction == 'pending_drag_or_tap' && !hasMoved) {
      if (pendingClickBoxId != null && pendingClickBoxId == selectedId) {
        // 点击已选中的元素，取消激活
        onSelect(null);
        debugPrint('✅ 点击已选中元素，取消激活: $pendingClickBoxId');
      }
    }

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
  void _cleanupInteraction(List<EditBoxData> boxes, String selectedId) {
    if (currentInteraction == 'resize' && selectedId.isNotEmpty) {
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      selectedBox.resizingHandle = null;
      selectedBox.resizeStartPosition = null;
      selectedBox.resizeAnchorPoint = null;
      debugPrint('调整大小结束');
    }

    if (currentInteraction == 'rotate' && selectedId.isNotEmpty) {
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      selectedBox.rotateLastPosition = null;
      debugPrint('旋转结束');
    }

    reset();
    debugPrint('指针抬起，重置状态');
  }

  /// 重置所有状态
  void reset() {
    currentInteraction = null;
    hasMoved = false;
    dragStartPosition = null;
    dragStartBoxPosition = null;
    pendingClickBoxId = null;
    lastScale = 1.0;
  }

  /// 检测点击了哪个元素或控制点
  String? _detectHitTarget(Offset position, EditBoxData box) {
    // 1. 检测旋转按钮
    final rotationCenter = EditContentBox.getRotationButtonCenter(box);
    if (_isPointInCircle(
      position,
      rotationCenter,
      EditContentBox.rotationButtonSize / 2,
    )) {
      return 'rotate';
    }

    // 2. 检测调整大小控制点
    final resizeHandles = EditContentBox.getResizeHandleCenters(box);
    for (var entry in resizeHandles.entries) {
      if (_isPointInCircle(
        position,
        entry.value,
        EditContentBox.hitTestSize / 2,
      )) {
        return 'resize:${entry.key}';
      }
    }

    // 3. 检测是否在元素内部
    final localX = position.dx - box.position.dx;
    final localY = position.dy - box.position.dy;

    final cos = math.cos(-box.rotation);
    final sin = math.sin(-box.rotation);
    final unrotatedX = localX * cos - localY * sin;
    final unrotatedY = localX * sin + localY * cos;

    if (unrotatedX >= 0 &&
        unrotatedX <= box.width &&
        unrotatedY >= 0 &&
        unrotatedY <= box.height) {
      return 'content';
    }

    return 'content';
  }

  /// 检测点是否在圆内
  bool _isPointInCircle(Offset point, Offset center, double radius) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return (dx * dx + dy * dy) <= (radius * radius);
  }

  /// 开始调整大小
  void _startResize(EditBoxData box, String handle, Offset position) {
    box.resizingHandle = handle;
    box.resizeStartWidth = box.width;
    box.resizeStartHeight = box.height;
    box.resizeAspectRatio = box.width / box.height; // 保存宽高比
    box.resizeStartPosition = position;

    Offset anchorPointLocal = Offset.zero;
    switch (handle) {
      case 'top-left':
        anchorPointLocal = Offset(box.width, box.height);
        break;
      case 'top':
        anchorPointLocal = Offset(box.width / 2, box.height);
        break;
      case 'top-right':
        anchorPointLocal = Offset(0, box.height);
        break;
      case 'right':
        anchorPointLocal = Offset(0, box.height / 2);
        break;
      case 'bottom-right':
        anchorPointLocal = Offset(0, 0);
        break;
      case 'bottom':
        anchorPointLocal = Offset(box.width / 2, 0);
        break;
      case 'bottom-left':
        anchorPointLocal = Offset(box.width, 0);
        break;
      case 'left':
        anchorPointLocal = Offset(box.width, box.height / 2);
        break;
    }

    final cos = math.cos(box.rotation);
    final sin = math.sin(box.rotation);
    final rotatedPoint = Offset(
      anchorPointLocal.dx * cos - anchorPointLocal.dy * sin,
      anchorPointLocal.dx * sin + anchorPointLocal.dy * cos,
    );

    box.resizeAnchorPoint = box.position + rotatedPoint;
  }

  /// 更新调整大小
  void _updateResize(EditBoxData box, Offset currentPosition) {
    if (box.resizingHandle == null ||
        box.resizeStartPosition == null ||
        box.resizeAnchorPoint == null) {
      return;
    }

    final delta = currentPosition - box.resizeStartPosition!;

    if (box.type == ElementType.line &&
        (box.resizingHandle! == 'top-left' ||
            box.resizingHandle! == 'top-right' ||
            box.resizingHandle! == 'bottom-right' ||
            box.resizingHandle! == 'bottom-left')) {
      return;
    }

    final cos = math.cos(-box.rotation);
    final sin = math.sin(-box.rotation);
    final adjustedDx = delta.dx * cos - delta.dy * sin;
    final adjustedDy = delta.dx * sin + delta.dy * cos;

    double newWidth = box.resizeStartWidth;
    double newHeight = box.resizeStartHeight;

    switch (box.resizingHandle!) {
      case 'top-left':
        // 角点：按比例缩放，使用对角线距离来计算缩放比例
        final scaleX =
            (box.resizeStartWidth - adjustedDx) / box.resizeStartWidth;
        final scaleY =
            (box.resizeStartHeight - adjustedDy) / box.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2; // 取平均值
        newWidth = (box.resizeStartWidth * scale).clamp(50.0, maxSize);
        newHeight = (newWidth / box.resizeAspectRatio).clamp(50.0, maxSize);
        // 重新调整宽度以确保高度在范围内
        newWidth = (newHeight * box.resizeAspectRatio).clamp(50.0, maxSize);
        break;
      case 'top':
        // 边中点：只改变高度
        if (box.type == ElementType.line) {
          newHeight = (box.resizeStartHeight - adjustedDy).clamp(20.0, maxSize);
        } else {
          newHeight = (box.resizeStartHeight - adjustedDy).clamp(50.0, maxSize);
        }
        break;
      case 'top-right':
        // 角点：按比例缩放
        final scaleX =
            (box.resizeStartWidth + adjustedDx) / box.resizeStartWidth;
        final scaleY =
            (box.resizeStartHeight - adjustedDy) / box.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (box.resizeStartWidth * scale).clamp(50.0, maxSize);
        newHeight = (newWidth / box.resizeAspectRatio).clamp(50.0, maxSize);
        newWidth = (newHeight * box.resizeAspectRatio).clamp(50.0, maxSize);
        break;
      case 'right':
        // 边中点：只改变宽度
        newWidth = (box.resizeStartWidth + adjustedDx).clamp(50.0, maxSize);
        break;
      case 'bottom-right':
        // 角点：按比例缩放
        final scaleX =
            (box.resizeStartWidth + adjustedDx) / box.resizeStartWidth;
        final scaleY =
            (box.resizeStartHeight + adjustedDy) / box.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (box.resizeStartWidth * scale).clamp(50.0, maxSize);
        newHeight = (newWidth / box.resizeAspectRatio).clamp(50.0, maxSize);
        newWidth = (newHeight * box.resizeAspectRatio).clamp(50.0, maxSize);
        break;
      case 'bottom':
        // 边中点：只改变高度
        if (box.type == ElementType.line) {
          newHeight = (box.resizeStartHeight + adjustedDy).clamp(20.0, maxSize);
        } else {
          newHeight = (box.resizeStartHeight + adjustedDy).clamp(50.0, maxSize);
        }
        break;
      case 'bottom-left':
        // 角点：按比例缩放
        final scaleX =
            (box.resizeStartWidth - adjustedDx) / box.resizeStartWidth;
        final scaleY =
            (box.resizeStartHeight + adjustedDy) / box.resizeStartHeight;
        final scale = (scaleX + scaleY) / 2;
        newWidth = (box.resizeStartWidth * scale).clamp(50.0, maxSize);
        newHeight = (newWidth / box.resizeAspectRatio).clamp(50.0, maxSize);
        newWidth = (newHeight * box.resizeAspectRatio).clamp(50.0, maxSize);
        break;
      case 'left':
        // 边中点：只改变宽度
        newWidth = (box.resizeStartWidth - adjustedDx).clamp(50.0, maxSize);
        break;
    }

    box.width = newWidth;
    box.height = newHeight;

    Offset newAnchorPointLocal = Offset.zero;
    switch (box.resizingHandle!) {
      case 'top-left':
        newAnchorPointLocal = Offset(box.width - 1.5, box.height - 1.5);
        break;
      case 'top':
        newAnchorPointLocal = Offset(box.width / 2, box.height - 1.5);
        break;
      case 'top-right':
        newAnchorPointLocal = Offset(1.5, box.height - 1.5);
        break;
      case 'right':
        newAnchorPointLocal = Offset(1.5, box.height / 2);
        break;
      case 'bottom-right':
        newAnchorPointLocal = Offset(1.5, 1.5);
        break;
      case 'bottom':
        newAnchorPointLocal = Offset(box.width / 2, 1.5);
        break;
      case 'bottom-left':
        newAnchorPointLocal = Offset(box.width - 1.5, 1.5);
        break;
      case 'left':
        newAnchorPointLocal = Offset(box.width - 1.5, box.height / 2);
        break;
    }

    final cosRot = math.cos(box.rotation);
    final sinRot = math.sin(box.rotation);
    final rotatedNewPoint = Offset(
      newAnchorPointLocal.dx * cosRot - newAnchorPointLocal.dy * sinRot,
      newAnchorPointLocal.dx * sinRot + newAnchorPointLocal.dy * cosRot,
    );

    box.position = box.resizeAnchorPoint! - rotatedNewPoint;
  }

  /// 更新旋转
  void _updateRotation(EditBoxData box, Offset currentPosition) {
    if (box.rotateLastPosition == null) return;

    final globalContainerCenter = Offset(
      box.position.dx + box.width / 2,
      box.position.dy + box.height / 2,
    );

    final currentAngle = math.atan2(
      currentPosition.dy - globalContainerCenter.dy,
      currentPosition.dx - globalContainerCenter.dx,
    );
    final lastAngle = math.atan2(
      box.rotateLastPosition!.dy - globalContainerCenter.dy,
      box.rotateLastPosition!.dx - globalContainerCenter.dx,
    );

    double angleDelta = currentAngle - lastAngle;

    if (angleDelta > math.pi) {
      angleDelta -= 2 * math.pi;
    } else if (angleDelta < -math.pi) {
      angleDelta += 2 * math.pi;
    }

    box.rotation += angleDelta;
    box.rotateLastPosition = currentPosition;
  }

  /// 计算两个指针之间的距离
  double _computeScale() {
    if (pointers.length < 2) return 1.0;

    final positions = pointers.values.toList();
    final dx = positions[0].dx - positions[1].dx;
    final dy = positions[0].dy - positions[1].dy;
    return (dx * dx + dy * dy).abs();
  }
}
