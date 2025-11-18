import 'package:flutter/widgets.dart';
import 'gesture_config.dart';
import 'pointer_tracker.dart';

/// 融合 PointerTracker + 状态机
/// 负责识别：
/// - 单指 → 拖动
/// - 多指 → 缩放 / 旋转
/// - 点击判定
class GestureStateMachine {
  final GestureConfig config;
  final PointerTracker pointerTracker;

  final void Function(Offset delta)? onPan;
  final void Function(double scale, double rotation, Offset focal)? onScale;
  final void Function(Offset pos)? onTap;
  final void Function(Offset pos)? onTapUp;

  GestureStateMachine({
    required this.config,
    required this.pointerTracker,
    this.onPan,
    this.onScale,
    this.onTap,
    this.onTapUp,
  });

  // --- 状态相关 ---
  Offset? _lastSingleFingerPos;
  bool _isScaling = false;

  // ============================================
  // Pointer 生命周期
  // ============================================
  void onPointerDown(PointerDownEvent e) {
    if (pointerTracker.count == 1) {
      _lastSingleFingerPos = e.localPosition;
    }
  }

  void onPointerMove(PointerMoveEvent e) {
    if (pointerTracker.count == 1) {
      _handleSingleFingerMove(e);
    } else if (pointerTracker.count >= 2) {
      _handleMultiFingerMove();
    }
  }

  void onPointerUp(PointerUpEvent e) {
    _handlePointerEnd(e.localPosition);
  }

  void onPointerCancel(PointerCancelEvent e) {
    _handlePointerEnd(e.localPosition);
  }

  // ============================================
  // GestureDetector tap 系列
  // ============================================
  void onTapDown(Offset pos) {}

  void onTapUpState(Offset pos) {
    onTapUp?.call(pos);
    onTap?.call(pos);
  }

  // ============================================
  // 单指拖动
  // ============================================
  void _handleSingleFingerMove(PointerMoveEvent e) {
    if (_isScaling) return;

    final last = _lastSingleFingerPos;
    if (last == null) return;

    final delta = e.localPosition - last;

    if (delta.distance < config.panMinDistance) return;

    _lastSingleFingerPos = e.localPosition;

    onPan?.call(delta);
  }

  // ============================================
  // 多指（裸识别） → scale/rotate
  // ============================================
  void _handleMultiFingerMove() {
    final two = pointerTracker.getTwoFingerInfo();
    if (two == null) return;

    _isScaling = true;

    final scale = two.scale;
    final rotate = two.rotation;
    final focal = two.focalPoint;

    onScale?.call(scale, rotate, focal);
  }

  // ============================================
  // 结束手势
  // ============================================
  void _handlePointerEnd(Offset pos) {
    _lastSingleFingerPos = null;
    if (pointerTracker.count < 2) {
      _isScaling = false;
    }
  }
}
