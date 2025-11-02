import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/create_design_model.dart';
import '../edit_box/edit_content_box.dart';
import '../../../utils/text_measure_util.dart';

/// 画布手势管理器： 负责处理所有的手势交互逻辑
class CanvasGestureManager {
  // 文本类型的文本框，处于激活状态时，点击弹出输入框
  void Function(String boxId)? onDoubleTap;
  // 判断点击是否是文本框内
  bool isTapBox = false;

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
  static const double minFontSize = 5.0; // 最小字体大小
  static const double minBoxSize = 5.0; // 最小文本框尺寸（用于非文本类型或后备）

  // 边框宽度（与 EditContentBox 保持一致）
  static const double borderWidth = 3.0;

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

    isTapBox = false;

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
          isTapBox = true;
          pendingClickBoxId = selectedId; // 保存可能要取消激活的元素ID
          dragStartBoxPosition = selectedBox.position;
          // 初始化缩放中心点（外层容器包含边框）
          if (selectedBox.fixedScaleCenter == null) {
            final totalWidth = selectedBox.width + borderWidth * 2;
            final totalHeight = selectedBox.height + borderWidth * 2;
            selectedBox.fixedScaleCenter = Offset(
              selectedBox.position.dx + totalWidth / 2,
              selectedBox.position.dy + totalHeight / 2,
            );
            selectedBox.initialWidth = selectedBox.width;
            selectedBox.initialHeight = selectedBox.height;
            // 保存初始字体大小（仅文本类型）
            if (selectedBox.type == ElementType.text) {
              selectedBox.initialFontSize = selectedBox.fontSize;
            }
          }

          debugPrint('✅ 待定状态: 可能拖动或点击取消激活 $selectedId');
          return;
        }
      } else {
        // 待定状态：可能是拖动，也可能是点击取消激活
        currentInteraction = 'pending_drag_or_tap';
        pendingClickBoxId = selectedId; // 保存可能要取消激活的元素ID
        dragStartBoxPosition = selectedBox.position;
        // 初始化缩放中心点（外层容器包含边框）
        if (selectedBox.fixedScaleCenter == null) {
          final totalWidth = selectedBox.width + borderWidth * 2;
          final totalHeight = selectedBox.height + borderWidth * 2;
          selectedBox.fixedScaleCenter = Offset(
            selectedBox.position.dx + totalWidth / 2,
            selectedBox.position.dy + totalHeight / 2,
          );
          selectedBox.initialWidth = selectedBox.width;
          selectedBox.initialHeight = selectedBox.height;
          // 保存初始字体大小（仅文本类型）
          if (selectedBox.type == ElementType.text) {
            selectedBox.initialFontSize = selectedBox.fontSize;
          }
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

    // 始终重新计算缩放中心点（基于当前文本框的中心）
    final totalWidth = selectedBox.width + borderWidth * 2;
    final totalHeight = selectedBox.height + borderWidth * 2;
    selectedBox.fixedScaleCenter = Offset(
      selectedBox.position.dx + totalWidth / 2,
      selectedBox.position.dy + totalHeight / 2,
    );
    selectedBox.initialWidth = selectedBox.width;
    selectedBox.initialHeight = selectedBox.height;
    // 保存初始字体大小（仅文本类型）
    if (selectedBox.type == ElementType.text) {
      selectedBox.initialFontSize = selectedBox.fontSize;
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
      // 对于文本类型，根据最小字体大小计算最小尺寸
      double minWidth = 50.0;
      double minHeight = 50.0;
      if (selectedBox.type == ElementType.text) {
        final minTextSize = _calculateMinTextSize(selectedBox);
        minWidth = minTextSize.width;
        minHeight = minTextSize.height;
      }

      final newWidth = (selectedBox.initialWidth * selectedBox.cumulativeScale)
          .clamp(minWidth, double.infinity);
      final newHeight =
          (selectedBox.initialHeight * selectedBox.cumulativeScale).clamp(
            minHeight,
            double.infinity,
          );

      // 计算新的外层容器总尺寸（包含边框）
      final totalNewWidth = newWidth + borderWidth * 2;
      final totalNewHeight = newHeight + borderWidth * 2;

      // 使用包含边框的总尺寸来计算位置，确保缩放中心点正确
      final newPosition = Offset(
        selectedBox.fixedScaleCenter!.dx - totalNewWidth / 2,
        selectedBox.fixedScaleCenter!.dy - totalNewHeight / 2,
      );

      selectedBox.position = newPosition;
      selectedBox.width = newWidth;
      selectedBox.height = newHeight;

      // 如果是文本类型，同时缩放字体大小
      if (selectedBox.type == ElementType.text) {
        selectedBox.fontSize =
            (selectedBox.initialFontSize * selectedBox.cumulativeScale).clamp(
              minFontSize,
              double.infinity,
            );
      }
      // 移除频繁的调试打印，提升性能

      debugPrint("=======$minWidth====$minHeight==");
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
        final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
        if (selectedBox.type == ElementType.text && isTapBox) {
          onDoubleTap?.call(selectedId);
        } else {
          onSelect(null);
        }
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
    // 外层容器始终包含边框
    final totalWidth = box.width + borderWidth * 2;
    final totalHeight = box.height + borderWidth * 2;

    final localX = position.dx - box.position.dx;
    final localY = position.dy - box.position.dy;

    final cos = math.cos(-box.rotation);
    final sin = math.sin(-box.rotation);
    final unrotatedX = localX * cos - localY * sin;
    final unrotatedY = localX * sin + localY * cos;

    // 判断是否在外层容器内（包含边框区域）
    if (unrotatedX >= 0 &&
        unrotatedX <= totalWidth &&
        unrotatedY >= 0 &&
        unrotatedY <= totalHeight) {
      return 'content';
    }

    return null;
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
    // 保存初始字体大小、行高、字间距（仅文本类型）
    if (box.type == ElementType.text) {
      box.resizeStartFontSize = box.fontSize;
      box.resizeStartLineHeight = box.lineHeight;
      box.resizeStartFontSpace = box.fontSpace;
    }

    // 计算外层容器总尺寸（包含边框）
    final totalStartWidth = box.width + borderWidth * 2;
    final totalStartHeight = box.height + borderWidth * 2;

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

    // 文本类型特殊处理
    if (box.type == ElementType.text) {
      // 计算最小文本尺寸
      final minTextSize = _calculateMinTextSize(box);
      final minWidth = minTextSize.width;
      final minHeight = minTextSize.height;

      switch (box.resizingHandle!) {
        case 'left':
        case 'right':
          // 左右控制点：只改变宽度，高度根据文本自动计算
          if (box.resizingHandle! == 'right') {
            newWidth = (box.resizeStartWidth + adjustedDx).clamp(
              minWidth,
              maxSize,
            );
          } else {
            newWidth = (box.resizeStartWidth - adjustedDx).clamp(
              minWidth,
              maxSize,
            );
          }
          // 根据新宽度计算文本高度
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
          // 角点：按比例缩放
          final scaleX = box.resizingHandle!.contains('right')
              ? (box.resizeStartWidth + adjustedDx) / box.resizeStartWidth
              : (box.resizeStartWidth - adjustedDx) / box.resizeStartWidth;
          final scaleY = box.resizingHandle!.contains('bottom')
              ? (box.resizeStartHeight + adjustedDy) / box.resizeStartHeight
              : (box.resizeStartHeight - adjustedDy) / box.resizeStartHeight;
          final scale = (scaleX + scaleY) / 2;

          // 判断是否是多行文本（宽度小于单行所需宽度）
          final singleLineSize = TextMeasureUtil.measureText(
            text: box.text,
            fontSize: box.resizeStartFontSize,
            fontFamily: box.fontFamily,
            fontWeight: box.fontWeight,
            letterSpacing: box.resizeStartFontSpace,
            lineHeight: box.resizeStartLineHeight,
          );
          final isMultiLine = box.resizeStartWidth < singleLineSize.width;

          if (isMultiLine) {
            // 多行文本：使用统一的scale同时缩放宽度、字体、行高、字间距，保持行数不变
            // 宽度和字体应该继续缩小，直到字体达到最小值，不受minWidth限制
            final scaledWidth = box.resizeStartWidth * scale;
            final scaledFontSize = box.resizeStartFontSize * scale;
            // 字间距（绝对值）也需要按比例缩放
            final scaledFontSpace = box.resizeStartFontSpace * scale;
            // 行高（相对于字体的倍数）保持不变，因为实际行高 = fontSize * lineHeight，已经随字体缩放了

            // 字体不能小于最小值
            final finalFontSize = math.max(scaledFontSize, minFontSize);
            // 字间距不能小于0
            final finalFontSpace = math.max(scaledFontSpace, 0.0);

            // 如果字体还能缩小，使用计算的宽度；如果字体已到最小值，按比例计算对应的宽度
            final finalWidth = (scaledFontSize >= minFontSize)
                ? scaledWidth
                : (box.resizeStartWidth *
                      (minFontSize / box.resizeStartFontSize));

            // 使用最终的宽度、字体、字间距、行高重新计算文本高度
            final textSize = TextMeasureUtil.measureTextWithWidth(
              text: box.text,
              fontSize: finalFontSize,
              fontFamily: box.fontFamily,
              fontWeight: box.fontWeight,
              letterSpacing: finalFontSpace,
              lineHeight: box.resizeStartLineHeight, // 行高倍数保持不变
              maxWidth: finalWidth,
            );

            // 宽度和高度允许缩小到比minWidth/minHeight更小，直到字体达到最小值
            newWidth = math.max(finalWidth, 0.0).clamp(0.0, maxSize);
            newHeight = math.max(textSize.height, 0.0).clamp(0.0, maxSize);
            box.fontSize = finalFontSize.clamp(minFontSize, 200.0);
            box.fontSpace = finalFontSpace;
            // lineHeight 保持不变，因为它是相对于字体的倍数
          } else {
            // 单行文本：按比例缩放，保持宽高比
            newWidth = (box.resizeStartWidth * scale).clamp(minWidth, maxSize);
            newHeight = (newWidth / box.resizeAspectRatio).clamp(
              minHeight,
              maxSize,
            );
            newWidth = (newHeight * box.resizeAspectRatio).clamp(
              minWidth,
              maxSize,
            );
            // 使用最终的实际宽度变化比例来缩放字体大小
            final actualScale = newWidth / box.resizeStartWidth;
            box.fontSize = (box.resizeStartFontSize * actualScale).clamp(
              minFontSize,
              200.0,
            );
          }
          break;
        default:
          // top 和 bottom 控制点不处理（文本类型没有这些控制点）
          break;
      }
    } else {
      // 非文本类型的原有逻辑
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
            newHeight = (box.resizeStartHeight - adjustedDy).clamp(
              20.0,
              maxSize,
            );
          } else {
            newHeight = (box.resizeStartHeight - adjustedDy).clamp(
              50.0,
              maxSize,
            );
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
            newHeight = (box.resizeStartHeight + adjustedDy).clamp(
              20.0,
              maxSize,
            );
          } else {
            newHeight = (box.resizeStartHeight + adjustedDy).clamp(
              50.0,
              maxSize,
            );
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
    }

    box.width = newWidth;
    box.height = newHeight;

    // 计算新的外层容器总尺寸（包含边框）
    final totalNewWidth = box.width + borderWidth * 2;
    final totalNewHeight = box.height + borderWidth * 2;

    Offset newAnchorPointLocal = Offset.zero;
    switch (box.resizingHandle!) {
      case 'top-left':
        // 新的右下角（相对于新的外层容器）
        newAnchorPointLocal = Offset(totalNewWidth, totalNewHeight);
        break;
      case 'top':
        // 新的下边中点
        newAnchorPointLocal = Offset(totalNewWidth / 2, totalNewHeight);
        break;
      case 'top-right':
        // 新的左下角
        newAnchorPointLocal = Offset(0, totalNewHeight);
        break;
      case 'right':
        // 新的左边中点
        newAnchorPointLocal = Offset(0, totalNewHeight / 2);
        break;
      case 'bottom-right':
        // 新的左上角
        newAnchorPointLocal = Offset(0, 0);
        break;
      case 'bottom':
        // 新的上边中点
        newAnchorPointLocal = Offset(totalNewWidth / 2, 0);
        break;
      case 'bottom-left':
        // 新的右上角
        newAnchorPointLocal = Offset(totalNewWidth, 0);
        break;
      case 'left':
        // 新的右边中点
        newAnchorPointLocal = Offset(totalNewWidth, totalNewHeight / 2);
        break;
    }

    final cosRot = math.cos(box.rotation);
    final sinRot = math.sin(box.rotation);
    final rotatedNewPoint = Offset(
      newAnchorPointLocal.dx * cosRot - newAnchorPointLocal.dy * sinRot,
      newAnchorPointLocal.dx * sinRot + newAnchorPointLocal.dy * cosRot,
    );

    // 根据固定锚点和新的对角点位置，计算新的外层容器位置
    box.position = box.resizeAnchorPoint! - rotatedNewPoint;
  }

  /// 更新旋转
  void _updateRotation(EditBoxData box, Offset currentPosition) {
    if (box.rotateLastPosition == null) return;

    // 计算容器中心（外层容器包含边框）
    final totalWidth = box.width + borderWidth * 2;
    final totalHeight = box.height + borderWidth * 2;
    final globalContainerCenter = Offset(
      box.position.dx + totalWidth / 2,
      box.position.dy + totalHeight / 2,
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

  /// 根据最小字体大小计算文本框的最小尺寸
  /// [box] 文本框数据
  /// 返回最小宽度和最小高度
  Size _calculateMinTextSize(EditBoxData box) {
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
