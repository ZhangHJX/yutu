import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import './canvas_element.dart';
import '../model/index.dart';

class MatrixUtilsX {
  /// screen -> canvas logical coords (uses canvasMatrix)
  static Offset screenToCanvas(Offset p, Matrix4 canvasMatrix) {
    final inv = Matrix4.inverted(canvasMatrix);
    final v = inv.transform3(Vector3(p.dx, p.dy, 0));
    return Offset(v.x, v.y);
  }

  /// canvas coords -> element local coords (uses element transform)
  static Offset canvasToElement(Offset p, Matrix4 elementMatrix) {
    final inv = Matrix4.inverted(elementMatrix);
    final v = inv.transform3(Vector3(p.dx, p.dy, 0));
    return Offset(v.x, v.y);
  }

  /// screen -> element local coords
  static Offset screenToElement(
    Offset screen,
    Matrix4 canvasMatrix,
    Matrix4 elementMatrix,
  ) {
    final inCanvas = screenToCanvas(screen, canvasMatrix);
    return canvasToElement(inCanvas, elementMatrix);
  }

  /// returns world (screen) positions of element corners (in order TL, TR, BR, BL)
  static List<Offset> worldCorners(CanvasElement e, Matrix4 canvasMatrix) {
    return e.localCorners.map((p) {
      final v = e.transform.transform3(Vector3(p.dx, p.dy, 0));
      final v2 = canvasMatrix.transform3(Vector3(v.x, v.y, 0));
      return Offset(v2.x, v2.y);
    }).toList();
  }

  static Offset elementWorldPosition(CanvasElement e, Matrix4 canvasMatrix) {
    // element origin (0,0) transformed to world
    final v = e.transform.transform3(Vector3(0, 0, 0));
    final v2 = canvasMatrix.transform3(Vector3(v.x, v.y, 0));
    return Offset(v2.x, v2.y);
  }

  // 将事件转换为本地坐标
  static Offset canvasLocal(Offset globalPosition, GlobalKey containerKey) {
    final RenderBox? canvasBox =
        containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox == null) return globalPosition;

    return canvasBox.globalToLocal(globalPosition);
  }
}

/// 手势相关的判断方法
extension MatrixUtilsXGesture on MatrixUtilsX {
  static CanvasElement? detectHitElement(
    PointerEvent event,
    GlobalKey containerKey,
    List<CanvasElement> boxes,
    Size canvalsSize,
    Matrix4 canvasMatrix,
  ) {
    final localPos = MatrixUtilsX.canvasLocal(event.position, containerKey);

    final isCanvals = MatrixUtilsXGesture.isPointInCanvas(
      localPos,
      canvalsSize,
    );
    if (!isCanvals) {
      return null;
    }

    // 遍历所有元素，从后向前（因为后面的元素在最上层）
    for (int i = boxes.length - 1; i >= 0; i--) {
      final box = boxes[i];
      final hitTarget = MatrixUtilsXGesture.detectHitTarget(
        localPos,
        box,
        canvasMatrix,
      );
      if (hitTarget != null) {
        return box;
      }
    }
    return null;
  }

  static String? detectHitTarget(
    Offset canvasPos,
    CanvasElement box,
    Matrix4 canvasMatrix,
  ) {
    box.updateMatrix4(); // 确保最新矩阵

    final worldPointer = _transformPoint(canvasMatrix, canvasPos);
    final rotationCenter = MatrixUtilsXGesture.worldRotationButtonCenter(
      box,
      canvasMatrix,
    );
    if (_hitCircle(worldPointer, rotationCenter, rotationButtonSize / 2)) {
      return 'rotate';
    }

    final handleCenters = MatrixUtilsXGesture.worldResizeHandleCenters(
      box,
      canvasMatrix,
    );
    final visibleHandles = MatrixUtilsXGesture.controlHandlesForType(
      box.type,
      box,
    );
    for (final handle in visibleHandles) {
      final targetCenter = handleCenters[handle];
      if (targetCenter == null) continue;
      if (_hitCircle(worldPointer, targetCenter, editHitCircleSize / 2)) {
        return 'resize:$handle';
      }
    }

    // ③ 本体命中（使用元素本地坐标，避免受画布变换影响）
    final local = MatrixUtilsX.canvasToElement(canvasPos, box.transform);
    if (local.dx >= 0 &&
        local.dx <= box.width &&
        local.dy >= 0 &&
        local.dy <= box.height) {
      return 'content';
    }

    return null;
  }

  /// 检测点是否在圆内
  static bool _hitCircle(Offset p, Offset center, double radius) {
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    return dx * dx + dy * dy <= radius * radius;
  }

  /// 检查点击位置是否在画布内
  static bool isPointInCanvas(Offset position, Size? canvasSize) {
    if (canvasSize == null) {
      // 如果没有设置画布尺寸，默认允许
      return true;
    }

    return position.dx >= 0 &&
        position.dx <= canvasSize.width &&
        position.dy >= 0 &&
        position.dy <= canvasSize.height;
  }

  static Map<String, Offset> worldResizeHandleCenters(
    CanvasElement element,
    Matrix4 canvasMatrix,
  ) {
    final corners = MatrixUtilsX.worldCorners(element, canvasMatrix);
    final tl = corners[0];
    final tr = corners[1];
    final br = corners[2];
    final bl = corners[3];

    return {
      'top-left': tl,
      'top-right': tr,
      'bottom-right': br,
      'bottom-left': bl,
      'top': Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2),
      'right': Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2),
      'bottom': Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2),
      'left': Offset((bl.dx + tl.dx) / 2, (bl.dy + tl.dy) / 2),
    };
  }

  static Offset worldRotationButtonCenter(
    CanvasElement element,
    Matrix4 canvasMatrix,
  ) {
    final corners = MatrixUtilsX.worldCorners(element, canvasMatrix);
    return _rotationHandleCenterFromCorners(corners);
  }

  static List<String> controlHandlesForType(
    ElementType type,
    CanvasElement element,
  ) {
    switch (type) {
      case ElementType.image:
      case ElementType.rectangle:
      case ElementType.ellipse:
        return [
          'top-left',
          'top',
          'top-right',
          'right',
          'bottom-right',
          'bottom',
          'bottom-left',
          'left',
        ];
      case ElementType.text:
        final totalHeight = element.height + editBorderWidth * 2;
        if (totalHeight < 25.0) {
          return ['bottom-right'];
        }
        return [
          'top-left',
          'top-right',
          'right',
          'bottom-right',
          'bottom-left',
          'left',
        ];
      case ElementType.line:
        return ['left', 'top', 'right', 'bottom'];
    }
  }

  static Offset _transformPoint(Matrix4 matrix, Offset point) {
    final vector = matrix.transform3(Vector3(point.dx, point.dy, 0));
    return Offset(vector.x, vector.y);
  }

  static Offset _rotationHandleCenterFromCorners(List<Offset> corners) {
    if (corners.length < 4) {
      return Offset.zero;
    }
    final tl = corners[0];
    final br = corners[2];
    final bl = corners[3];
    final bottomCenter = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
    final center = Offset((tl.dx + br.dx) / 2, (tl.dy + br.dy) / 2);
    final direction = bottomCenter - center;
    final magnitude = direction.distance;
    final outwardDistance = rotationButtonPadding + rotationButtonSize / 2;

    if (magnitude < 1e-3) {
      // 退化为默认向下偏移
      return bottomCenter + Offset(0, outwardDistance);
    }

    final normalized = direction / magnitude;
    return bottomCenter + normalized * outwardDistance;
  }
}
