part of '../element_gesture_manager.dart';

/// Interaction modes supported by the gesture manager.
enum _InteractionMode { idle, pendingDragOrTap, drag, rotate, resize, scale }

/// Records the element attributes at the beginning of an operation so we can
/// reliably push history commands when the gesture ends.
class _OperationSnapshot {
  Offset? position;
  double? rotation;
  double? width;
  double? height;
  double? cumulativeScale;
  double? fontSize;
  double? fontSpace;

  void clear() {
    position = null;
    rotation = null;
    width = null;
    height = null;
    cumulativeScale = null;
    fontSize = null;
    fontSpace = null;
  }
}

/// Aggregates runtime state for the current gesture interaction. Keeping it in a
/// single place makes debugging and resets much easier.
class _GestureSession {
  final Map<int, Offset> pointers = {};
  _InteractionMode mode = _InteractionMode.idle;
  bool hasMoved = false;
  Offset? dragStartPointer; // pointer position when drag started
  Offset? dragStartElementPosition; // element position when drag started
  double lastScaleDistance = 1.0;
  final _OperationSnapshot snapshot = _OperationSnapshot();

  bool get isActive => mode != _InteractionMode.idle;
  bool get isScaling => mode == _InteractionMode.scale;
  bool get isPendingDrag => mode == _InteractionMode.pendingDragOrTap;

  void updatePointer(int id, Offset position) {
    pointers[id] = position;
  }

  void removePointer(int id) {
    pointers.remove(id);
  }

  void resetPointers() {
    pointers.clear();
  }

  void beginMode(_InteractionMode newMode) {
    mode = newMode;
    hasMoved = false;
  }

  void markMoved() {
    hasMoved = true;
  }

  void reset() {
    mode = _InteractionMode.idle;
    hasMoved = false;
    dragStartPointer = null;
    dragStartElementPosition = null;
    lastScaleDistance = 1.0;
    snapshot.clear();
  }
}
