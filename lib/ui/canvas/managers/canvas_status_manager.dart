import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 画布平移和缩放手势管理器
/// 负责处理画布的拖动和缩放操作
class CanvasStatusManager {
  // 画布变换状态
  Offset _offset = Offset.zero; // 画布偏移量
  double _scale = 1.0; // 画布缩放比例

  // 拖动相关
  Offset? _panStartPosition; // 拖动开始位置
  Offset? _panStartOffset; // 拖动开始时的画布偏移
  bool _isPanning = false; // 是否正在拖动画布

  // 缩放相关
  final Map<int, Offset> _pointers = {}; // 用于缩放的多点触控
  double _lastScaleDistance = 0.0; // 上一次的缩放距离
  bool _isScaling = false; // 是否正在缩放画布

  // 缩放限制（25% - 300%）
  static const double minScale = 0.25;
  static const double maxScale = 3.0;

  List<double> numberArray = [
    0.25,
    0.5,
    0.8,
    1,
    1.2,
    1.4,
    1.6,
    1.8,
    2.0,
    2.2,
    2.4,
    2.6,
    2.8,
    3,
  ];

  // 回调函数
  void Function(Offset offset, double scale)? onTransformChanged;

  /// 获取当前偏移量
  Offset get offset => _offset;

  /// 获取当前缩放比例
  double get scale => _scale;

  /// 是否正在操作（拖动或缩放）
  bool get isActive => _isPanning || _isScaling;

  /// 处理指针按下事件
  void handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;

    if (_pointers.length == 1) {
      // 单指：准备拖动画布
      _isPanning = true;
      _panStartPosition = event.position;
      _panStartOffset = _offset;
    } else if (_pointers.length == 2) {
      // 双指：准备缩放画布
      _isScaling = true;
      _isPanning = false; // 缩放时停止拖动
      _lastScaleDistance = _computeScaleDistance();
    }
  }

  /// 处理指针移动事件
  bool handlePointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.position;

    bool hasChanged = false;

    if (_isPanning && _panStartPosition != null && _panStartOffset != null) {
      // 拖动画布
      final delta = event.position - _panStartPosition!;
      _offset = _panStartOffset! + delta;
      hasChanged = true;
    } else if (_isScaling && _pointers.length == 2) {
      // 缩放画布
      final currentDistance = _computeScaleDistance();
      if (_lastScaleDistance > 0) {
        final scaleDelta = currentDistance / _lastScaleDistance;
        _scale = (_scale * scaleDelta).clamp(minScale, maxScale);
        hasChanged = true;
      }
      _lastScaleDistance = currentDistance;
    }

    if (hasChanged) {
      _notifyTransformChanged();
    }

    return hasChanged;
  }

  /// 处理指针抬起事件
  void handlePointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);

    if (_pointers.isEmpty) {
      // 所有手指抬起，重置状态
      _resetInteractionState();
    } else if (_pointers.length == 1) {
      // 从双指变为单指，切换到拖动模式
      _isScaling = false;
      _isPanning = true;
      _lastScaleDistance = 0.0;
      final remainingPointer = _pointers.values.first;
      _panStartPosition = remainingPointer;
      _panStartOffset = _offset;
    }
  }

  /// 处理指针取消事件
  void handlePointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      _resetInteractionState();
    }
  }

  /// 重置交互状态
  void _resetInteractionState() {
    _isPanning = false;
    _isScaling = false;
    _panStartPosition = null;
    _panStartOffset = null;
    _lastScaleDistance = 0.0;
  }

  /// 计算两个指针之间的距离（用于缩放）
  double _computeScaleDistance() {
    if (_pointers.length < 2) return 0.0;

    final positions = _pointers.values.toList();
    final dx = positions[0].dx - positions[1].dx;
    final dy = positions[0].dy - positions[1].dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 通知变换改变
  void _notifyTransformChanged() {
    onTransformChanged?.call(_offset, _scale);
  }

  /// 重置画布变换
  void reset() {
    _offset = Offset.zero;
    _scale = 1.0;
    _resetInteractionState();
    _notifyTransformChanged();
  }

  /// 设置画布变换
  void setTransform(Offset offset, double scale) {
    _offset = offset;
    _scale = scale.clamp(minScale, maxScale);
    _notifyTransformChanged();
  }

  /// 重置缩放（保持偏移）
  void resetScale() {
    _scale = 1.0;
    _notifyTransformChanged();
  }

  /// 重置偏移（保持缩放）
  void resetOffset() {
    _offset = Offset.zero;
    _notifyTransformChanged();
  }

  /// 放大画布（每次增加10%）
  void zoomIn() {
    _scale = (_scale * 1.2).clamp(minScale, maxScale);
    _notifyTransformChanged();
  }

  /// 缩小画布（每次减少10%）
  void zoomOut() {
    _scale = (_scale / 1.1).clamp(minScale, maxScale);
    _notifyTransformChanged();
  }
}
