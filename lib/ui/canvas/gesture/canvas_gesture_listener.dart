import 'package:flutter/material.dart';

/// 手势回调类型定义
typedef OnPointerDown = void Function(PointerDownEvent event);
typedef OnPointerMove = void Function(PointerMoveEvent event);
typedef OnPointerUp = void Function(PointerUpEvent event);
typedef OnPointerCancel = void Function(PointerCancelEvent event);
typedef OnTap = void Function(PointerEvent event); // PointerUpEvent
typedef OnLongPress = void Function(PointerEvent event); //PointerDownEvent
typedef OnDoubleTap = void Function(PointerEvent event); // PointerUpEvent

/// 画布手势监听器 - 纯 Listener 实现
/// 通过指针事件直接识别手势（点击、长按、双击等）
class CanvasGestureListener extends StatefulWidget {
  /// 指针按下回调
  final OnPointerDown? onPointerDown;

  /// 指针移动回调
  final OnPointerMove? onPointerMove;

  /// 指针抬起回调
  final OnPointerUp? onPointerUp;

  /// 指针取消回调
  final OnPointerCancel? onPointerCancel;

  /// 单击回调 - 传递 PointerUpEvent 用于判断是否点击到元素
  final OnTap? onTap;

  /// 长按回调 - 传递 PointerDownEvent 用于判断是否点击到元素
  final OnLongPress? onLongPress;

  /// 双击回调 - 传递 PointerUpEvent 用于判断是否点击到元素
  final OnDoubleTap? onDoubleTap;

  /// 子组件
  final Widget child;

  /// 点击移动距离阈值（像素）
  final double tapSlop;

  /// 长按时间阈值（毫秒）
  final int longPressDuration;

  /// 双击间隔阈值（毫秒）
  final int doubleTapInterval;

  const CanvasGestureListener({
    super.key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    required this.child,
    this.tapSlop = 18.0, // Flutter 默认值
    this.longPressDuration = 500,
    this.doubleTapInterval = 300,
  });

  @override
  State<CanvasGestureListener> createState() => _CanvasGestureListenerState();
}

class _CanvasGestureListenerState extends State<CanvasGestureListener> {
  // 追踪指针信息
  late Map<int, _PointerTracker> _pointers;

  // 上次点击的 event 和时间
  PointerUpEvent? _lastTapEvent;
  DateTime? _lastTapTime;

  // 双击计数器
  int _tapCount = 0;

  // 长按定时器
  final Map<int, dynamic> _longPressTimers = {};

  @override
  void initState() {
    super.initState();
    _pointers = {};
  }

  @override
  void dispose() {
    // 清理所有长按定时器
    for (final timer in _longPressTimers.values) {
      timer?.cancel();
    }
    _longPressTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _handlePointerDown(event);
      },
      onPointerMove: (event) {
        _handlePointerMove(event);
      },
      onPointerUp: (event) {
        _handlePointerUp(event);
      },
      onPointerCancel: (event) {
        _handlePointerCancel(event);
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    // 记录指针信息
    _pointers[event.pointer] = _PointerTracker(
      position: event.position,
      time: DateTime.now(),
    );

    // 启动长按检测
    _startLongPressDetection(event.pointer, event);

    // 调用用户回调
    widget.onPointerDown?.call(event);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // 更新指针信息
    if (_pointers.containsKey(event.pointer)) {
      final tracker = _pointers[event.pointer]!;
      final distance = (event.position - tracker.position).distance;

      // 如果移动距离超过阈值，取消长按检测
      if (distance > widget.tapSlop) {
        _cancelLongPressDetection(event.pointer);
      }

      tracker.position = event.position;
    }

    // 调用用户回调
    widget.onPointerMove?.call(event);
  }

  void _handlePointerUp(PointerUpEvent event) {
    // 取消长按检测
    _cancelLongPressDetection(event.pointer);

    final tracker = _pointers.remove(event.pointer);

    // 调用用户回调
    widget.onPointerUp?.call(event);

    if (tracker != null) {
      _recognizeGestures(event, tracker);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // 取消长按检测
    _cancelLongPressDetection(event.pointer);

    _pointers.remove(event.pointer);

    // 调用用户回调
    widget.onPointerCancel?.call(event);
  }

  /// 启动长按检测
  void _startLongPressDetection(int pointer, PointerDownEvent downEvent) {
    if (widget.onLongPress == null) return;

    _longPressTimers[pointer] = Future.delayed(
      Duration(milliseconds: widget.longPressDuration),
      () {
        if (mounted && _pointers.containsKey(pointer)) {
          // 调用长按回调，传递原始的 PointerDownEvent
          widget.onLongPress?.call(downEvent);
          _pointers.remove(pointer); // 移除指针，阻止后续的 tap 识别
        }
      },
    );
  }

  /// 取消长按检测
  void _cancelLongPressDetection(int pointer) {
    _longPressTimers.remove(pointer);
  }

  /// 识别手势
  void _recognizeGestures(PointerUpEvent event, _PointerTracker tracker) {
    final duration = DateTime.now().difference(tracker.time).inMilliseconds;
    final distance = (event.position - tracker.position).distance;

    // 检查是否是点击（移动距离小 + 快速释放）
    if (distance < widget.tapSlop && duration < 200) {
      _handleTapOrDoubleTap(event);
    }
  }

  void _handleTapOrDoubleTap(PointerUpEvent event) {
    final now = DateTime.now();

    // 检查是否是双击
    if (_lastTapEvent != null &&
        _lastTapTime != null &&
        (now.difference(_lastTapTime!).inMilliseconds <
            widget.doubleTapInterval) &&
        (_lastTapEvent!.position - event.position).distance < widget.tapSlop) {
      // 双击
      _tapCount++;
      if (_tapCount == 2) {
        // 调用双击回调，传递当前的 PointerUpEvent
        widget.onDoubleTap?.call(event);
        _tapCount = 0;
        _lastTapTime = null;
        _lastTapEvent = null;
        return;
      }
    } else {
      // 重置双击计数
      _tapCount = 1;
    }

    // 记录点击信息
    _lastTapEvent = event;
    _lastTapTime = now;

    // 延迟判断是否是单击（等待看是否有第二次点击）
    Future.delayed(Duration(milliseconds: widget.doubleTapInterval), () {
      if (mounted && _tapCount == 1 && _lastTapTime == now) {
        // 确认是单击，调用回调，传递事件
        widget.onTap?.call(event);
      }
    });
  }
}

/// 指针追踪信息
class _PointerTracker {
  Offset position;
  final DateTime time;

  _PointerTracker({required this.position, required this.time});
}
