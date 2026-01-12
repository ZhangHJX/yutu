import 'package:flutter/material.dart';

class CanvasCustomListener extends StatefulWidget {
  final Widget child;

  /// 原始 Listener 回调
  final void Function(PointerDownEvent event)? onPointerDown;
  final void Function(PointerMoveEvent event)? onPointerMove;
  final void Function(PointerUpEvent event)? onPointerUp;
  final void Function(PointerCancelEvent event)? onPointerCancel;

  /// 额外提供的点击回调
  final VoidCallback? onTap;

  // 允许的最大移动距离（视为点击）
  final double maxTapDistance;

  // 允许的最大点击时长（视为点击）
  final Duration maxTapDuration;

  const CanvasCustomListener({
    super.key,
    required this.child,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.onTap,
    this.maxTapDistance = 8.0,
    this.maxTapDuration = const Duration(milliseconds: 250),
  });

  @override
  State<CanvasCustomListener> createState() => _CanvasCustomListenerState();
}

class _CanvasCustomListenerState extends State<CanvasCustomListener> {
  Offset? _downPosition;
  DateTime? _downTime;
  int? _pointer;
  bool _movedTooFar = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _pointer = event.pointer;
        _downPosition = event.position;
        _downTime = DateTime.now();
        _movedTooFar = false;

        widget.onPointerDown?.call(event);
      },
      onPointerMove: (event) {
        // 只跟踪当前 pointer
        if (_pointer == event.pointer && _downPosition != null) {
          final distance = (event.position - _downPosition!)
              .distance; // Offset 有 distance getter
          if (distance > widget.maxTapDistance) {
            _movedTooFar = true; // 视为拖动，不再触发 tap
          }
        }

        widget.onPointerMove?.call(event);
      },
      onPointerUp: (event) {
        widget.onPointerUp?.call(event);

        if (_pointer == event.pointer &&
            !_movedTooFar &&
            _downTime != null &&
            widget.onTap != null) {
          final duration = DateTime.now().difference(_downTime!);
          if (duration <= widget.maxTapDuration) {
            // 符合“点击”的条件，触发 onTap
            widget.onTap!.call();
          }
        }

        // 重置状态
        _resetTracking();
      },
      onPointerCancel: (event) {
        widget.onPointerCancel?.call(event);
        // 取消时也重置
        _resetTracking();
      },
      child: widget.child,
    );
  }

  void _resetTracking() {
    _pointer = null;
    _downPosition = null;
    _downTime = null;
    _movedTooFar = false;
  }
}
