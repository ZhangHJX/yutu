import 'package:flutter/widgets.dart';
import 'gesture_config.dart';
import 'pointer_tracker.dart';
import 'gesture_state_machine.dart';

/// CanvasGestureCoordinator
/// -----------------------
/// 统一监听 Pointer + GestureDetector，
/// 输出稳定的：
/// - onCanvasPan
/// - onCanvasScale
/// - onCanvasTap
/// - onCanvasTapUp
///
/// 适合：完整 Matrix4 画布系统。
class CanvasGestureCoordinator extends StatefulWidget {
  final Widget child;

  final GestureConfig config;

  /// 回调：单指拖拽（画布平移 or 单选元素拖动）
  final void Function(Offset delta)? onCanvasPan;

  /// 回调：双指缩放/旋转（画布统一 Matrix4）
  final void Function(double scale, double rotation, Offset focalPoint)?
  onCanvasScale;

  /// 回调：点击
  final void Function(Offset pos)? onCanvasTap;

  /// 回调：抬起
  final void Function(Offset pos)? onCanvasTapUp;

  const CanvasGestureCoordinator({
    super.key,
    required this.child,
    this.onCanvasPan,
    this.onCanvasScale,
    this.onCanvasTap,
    this.onCanvasTapUp,
    this.config = const GestureConfig(),
  });

  @override
  State<CanvasGestureCoordinator> createState() =>
      _CanvasGestureCoordinatorState();
}

class _CanvasGestureCoordinatorState extends State<CanvasGestureCoordinator> {
  final PointerTracker _pointerTracker = PointerTracker();
  late GestureStateMachine _stateMachine;

  @override
  void initState() {
    super.initState();
    _stateMachine = GestureStateMachine(
      config: widget.config,
      pointerTracker: _pointerTracker,
      onPan: widget.onCanvasPan,
      onScale: widget.onCanvasScale,
      onTap: widget.onCanvasTap,
      onTapUp: widget.onCanvasTapUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,

      // pointer ↓
      onPointerDown: (event) {
        _pointerTracker.addPointer(event);
        _stateMachine.onPointerDown(event);
      },
      onPointerMove: (event) {
        _pointerTracker.updatePointer(event);
        _stateMachine.onPointerMove(event);
      },
      onPointerUp: (event) {
        _pointerTracker.removePointer(event);
        _stateMachine.onPointerUp(event);
      },
      onPointerCancel: (event) {
        _pointerTracker.removePointer(event);
        _stateMachine.onPointerCancel(event);
      },

      // gesture ↑（用于 click / tapUp / longPress 等）
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          _stateMachine.onTapDown(details.localPosition);
        },
        onTapUp: (details) {
          _stateMachine.onTapUpState(details.localPosition);
        },
        onTap: () {
          // 最终 tap（区分单击/双击需要在 stateMachine 内处理）
        },
        // 这里刻意不使用 onScaleStart/Update，
        // 全部交给 PointerTracker 做 “裸” 多指处理
      ),
    );
  }
}
