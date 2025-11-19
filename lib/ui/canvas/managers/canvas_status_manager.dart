import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../model/index.dart';

/// 画布状态管理器：处理平移和缩放手势
class CanvasStatusManager {
  Matrix4 matrix = Matrix4.identity();
  void Function(Matrix4 matrix, double scale, Offset offset)? onMatrixChanged;

  final Map<int, Offset> _pointers = {};

  // 拖动状态
  Offset? _panStartPos;
  Matrix4? _panStartMatrix;

  // 缩放状态
  double? _scaleStartDistance;
  Offset? _scaleStartFocalPoint; // 双指中心在画布坐标中的位置（固定基准点）

  static const double minScale = 0.25;
  static const double maxScale = 3.0;

  void handlePointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;

    if (_pointers.length == 1) {
      // 单指：开始拖动
      _panStartPos = e.position;
      _panStartMatrix = matrix.clone();
    } else if (_pointers.length == 2) {
      // 双指：开始缩放
      _scaleStartDistance = _getDistance();
      _scaleStartFocalPoint = MatrixUtilsX.screenToCanvas(
        _getFocalPoint(),
        matrix,
      );
    }
  }

  bool handlePointerMove(PointerMoveEvent e) {
    _pointers[e.pointer] = e.position;
    bool changed = false;

    if (_pointers.length == 1 && _panStartPos != null) {
      // 单指拖动
      changed = _handlePan();
    } else if (_pointers.length == 2 && _scaleStartDistance != null) {
      // 双指缩放
      changed = _handleScale();
    }

    if (changed) {
      final translation = matrix.getTranslation();
      onMatrixChanged?.call(
        matrix.clone(),
        _getScale(),
        Offset(translation.x, translation.y),
      );
    }

    return changed;
  }

  void handlePointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);

    if (_pointers.isEmpty) {
      _reset();
    } else if (_pointers.length == 1) {
      // 切换到单指拖动模式
      _panStartPos = _pointers.values.first;
      _panStartMatrix = matrix.clone();
    }
  }

  void handlePointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.isEmpty) _reset();
  }

  // ====================== 私有方法 ======================

  bool _handlePan() {
    if (_panStartPos == null || _panStartMatrix == null) return false;

    final currentPos = _pointers.values.first;
    final delta = currentPos - _panStartPos!;

    // 直接从开始矩阵添加平移
    matrix = _panStartMatrix!.clone();
    matrix.translateByVector3(Vector3(delta.dx, delta.dy, 0));

    return true;
  }

  bool _handleScale() {
    if (_scaleStartDistance == null || _scaleStartFocalPoint == null) {
      return false;
    }

    final nowDistance = _getDistance();
    if (nowDistance == 0) return false;

    // 计算缩放比例
    final scaleDelta = nowDistance / _scaleStartDistance!;
    final currentScale = _getScale();
    final newScale = (currentScale * scaleDelta).clamp(minScale, maxScale);
    final trueScale = newScale / currentScale;

    // 获取当前双指中心（屏幕坐标）
    final focalScreen = _getFocalPoint();

    // 构建缩放矩阵：以画布坐标中的基准点为中心进行缩放
    // 变换顺序：T(focal) * S(scale) * T(-focal) * M
    final scaleTransform = Matrix4.identity()
      ..translateByVector3(
        Vector3(_scaleStartFocalPoint!.dx, _scaleStartFocalPoint!.dy, 0),
      )
      ..scaleByVector3(Vector3(trueScale, trueScale, 1))
      ..translateByVector3(
        Vector3(-_scaleStartFocalPoint!.dx, -_scaleStartFocalPoint!.dy, 0),
      );

    // 应用缩放到当前矩阵
    matrix = matrix.multiplied(scaleTransform);

    // 调整平移以保持双指中心在屏幕上不动
    // 计算缩放后基准点的屏幕位置
    final scaledFocalScreen = matrix.transform3(
      Vector3(_scaleStartFocalPoint!.dx, _scaleStartFocalPoint!.dy, 0),
    );

    // 计算需要补偿的平移
    final compensation =
        focalScreen - Offset(scaledFocalScreen.x, scaledFocalScreen.y);

    // 添加补偿平移
    matrix.translateByVector3(Vector3(compensation.dx, compensation.dy, 0));

    _scaleStartDistance = nowDistance;
    return true;
  }

  /// 获取两个指针之间的距离
  double _getDistance() {
    final ps = _pointers.values.toList();
    if (ps.length < 2) return 0;
    return (ps[1] - ps[0]).distance;
  }

  /// 获取两个指针的中心点（屏幕坐标）
  Offset _getFocalPoint() {
    final ps = _pointers.values.toList();
    if (ps.length < 2) return ps.isNotEmpty ? ps[0] : Offset.zero;
    return Offset((ps[0].dx + ps[1].dx) / 2, (ps[0].dy + ps[1].dy) / 2);
  }

  /// 从矩阵提取缩放值
  double _getScale() {
    // 取矩阵的 X 和 Y 缩放分量
    return (matrix[0] + matrix[5]) / 2.0;
  }

  void _reset() {
    _panStartPos = null;
    _panStartMatrix = null;
    _scaleStartDistance = null;
    _scaleStartFocalPoint = null;
  }
}

/// 扩展的方法
extension CanvasStatusManagerMinx on CanvasStatusManager {
  // ====================== 公共方法 ======================

  /// 重置画布到初始状态（恢复缩放和平移）
  /// 使用场景：点击"适应屏幕"、"重置"按钮时调用
  /// 示例：
  /// ```dart
  /// _canvasStatusManager.resetMatrix();
  /// ```
  void resetMatrix() {
    matrix = Matrix4.identity();
    _reset();
    onMatrixChanged?.call(matrix.clone(), _getScale(), Offset.zero);
  }

  /// 恢复到指定的矩阵状态
  /// 使用场景：撤销/重做、恢复保存的状态时调用
  /// 参数：targetMatrix - 要恢复到的矩阵状态
  /// 示例：
  /// ```dart
  /// Matrix4 savedMatrix = _canvasStatusManager.getMatrix();
  /// // ... 后续操作 ...
  /// _canvasStatusManager.restoreMatrix(savedMatrix);
  /// ```
  void restoreMatrix(Matrix4 targetMatrix) {
    matrix = targetMatrix.clone();
    _reset();
    final translation = matrix.getTranslation();
    onMatrixChanged?.call(
      matrix.clone(),
      _getScale(),
      Offset(translation.x, translation.y),
    );
  }

  /// 获取当前矩阵状态（用于保存）
  /// 返回：当前的 Matrix4 克隆
  /// 示例：
  /// ```dart
  /// Matrix4 currentState = _canvasStatusManager.getMatrix();
  /// // 保存到历史记录或数据库
  /// ```
  Matrix4 getMatrix() => matrix.clone();

  /// 获取当前缩放比例
  /// 返回：0.25 ~ 3.0 之间的缩放值
  /// 示例：
  /// ```dart
  /// double scale = _canvasStatusManager.getScale();
  /// print('Current scale: $scale');
  /// ```
  double getScale() => _getScale();

  /// 获取当前偏移量
  /// 返回：平移后的 Offset
  /// 示例：
  /// ```dart
  /// Offset offset = _canvasStatusManager.getOffset();
  /// print('Current offset: x=${offset.dx}, y=${offset.dy}');
  /// ```
  Offset getOffset() {
    final translation = matrix.getTranslation();
    return Offset(translation.x, translation.y);
  }
}
