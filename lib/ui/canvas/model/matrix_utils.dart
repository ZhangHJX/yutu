import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import './canvas_element.dart';

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
