import 'package:flutter/widgets.dart';

/// PointerTracker
/// 捕获所有 Pointer 信息，支持：
/// - 两指计算 scale / rotation / focalPoint
/// - 第 N 指扩展
class PointerTracker {
  final Map<int, PointerEvent> _pointers = {};

  int get count => _pointers.length;

  void addPointer(PointerDownEvent e) {
    _pointers[e.pointer] = e;
  }

  void updatePointer(PointerMoveEvent e) {
    _pointers[e.pointer] = e;
  }

  void removePointer(PointerEvent e) {
    _pointers.remove(e.pointer);
  }

  /// 仅用于双指时的数学信息
  TwoFingerInfo? getTwoFingerInfo() {
    if (_pointers.length < 2) return null;
    final p = _pointers.values.toList();

    final a = p[0];
    final b = p[1];

    final Offset pA = a.localPosition;
    final Offset pB = b.localPosition;

    final Offset prevA = a.localPosition - a.delta;
    final Offset prevB = b.localPosition - b.delta;

    final double oldDist = (prevA - prevB).distance;
    final double newDist = (pA - pB).distance;

    final double scale = oldDist == 0 ? 1.0 : newDist / oldDist;

    // 旋转量
    final double oldAngle = (prevB - prevA).direction;
    final double newAngle = (pB - pA).direction;
    final double rotation = newAngle - oldAngle;

    final focal = (pA + pB) / 2;

    return TwoFingerInfo(scale: scale, rotation: rotation, focalPoint: focal);
  }
}

class TwoFingerInfo {
  final double scale;
  final double rotation;
  final Offset focalPoint;

  TwoFingerInfo({
    required this.scale,
    required this.rotation,
    required this.focalPoint,
  });
}
