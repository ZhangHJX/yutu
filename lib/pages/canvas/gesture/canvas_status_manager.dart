import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:common/common.dart';
import '../model/index.dart';
import 'dart:math' as math;

/// 画布状态管理器：处理平移和缩放手势
class CanvasStatusManager {
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

  void handlePointerDown(PointerDownEvent e, bool isLock) {
    if (isLock) {
      return;
    }
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

  bool handlePointerMove(PointerMoveEvent e, bool isLock) {
    if (isLock) {
      return false;
    }
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

  void handlePointerUp(PointerUpEvent e, bool isLock) {
    if (isLock) {
      return;
    }
    _pointers.remove(e.pointer);

    if (_pointers.isEmpty) {
      _reset();
    } else if (_pointers.length == 1) {
      // 切换到单指拖动模式
      _panStartPos = _pointers.values.first;
      _panStartMatrix = matrix.clone();
    }
  }

  void handlePointerCancel(PointerCancelEvent e, bool isLock) {
    if (isLock) {
      return;
    }
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

    // 获取当前双指中心（屏幕坐标）
    final focalScreen = _getFocalPoint();

    // 计算缩放比例（本次缩放的增量）
    final scaleDelta = nowDistance / _scaleStartDistance!;
    final currentScale = _getScale();
    final newScale = (currentScale * scaleDelta).clamp(minScale, maxScale);

    // 计算真实的缩放倍数（可能被限制）
    final trueScale = newScale / currentScale;

    // 如果缩放倍数太小，跳过
    if ((trueScale - 1.0).abs() < 0.001) {
      return false;
    }

    // 构建缩放矩阵：以画布坐标中的基准点为中心进行缩放
    // 变换顺序：T(focal) * S(scale) * T(-focal)
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

    // 限制补偿范围，避免浮点误差导致的大幅跳跃
    final maxCompensation = 30.0; // 最大补偿 30 像素
    final clampedCompensation = Offset(
      compensation.dx.clamp(-maxCompensation, maxCompensation),
      compensation.dy.clamp(-maxCompensation, maxCompensation),
    );

    // 添加补偿平移
    matrix.translateByVector3(
      Vector3(clampedCompensation.dx, clampedCompensation.dy, 0),
    );

    // 更新起始距离为当前距离
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

  /// 放大：跳到 numberArray 的下一档
  void zoomIn(Size canvasSize) {
    _jumpZoomOnCanvasCenter(canvasSize, enlarge: true);
  }

  /// 缩小：跳到 numberArray 的上一档
  void zoomOut(Size canvasSize) {
    _jumpZoomOnCanvasCenter(canvasSize, enlarge: false);
  }

  /// 内部缩放逻辑：以画布中心为缩放基准
  void _jumpZoomOnCanvasCenter(Size canvasSize, {required bool enlarge}) {
    final current = _getScale();

    // 找下一档 / 上一档
    double target = current;
    if (enlarge) {
      for (final v in numberArray) {
        if (v > current) {
          target = v;
          break;
        }
      }
    } else {
      for (final v in numberArray.reversed) {
        if (v < current) {
          target = v;
          break;
        }
      }
    }

    // 限制范围
    target = target.clamp(minScale, maxScale);
    if ((target - current).abs() < 0.001) return;

    // 本次真实缩放倍数
    final trueScale = target / current;

    // 🎯 画布中心点（屏幕坐标）
    final centerScreen = Offset(canvasSize.width / 2, canvasSize.height / 2);
    // 🎯 转换为画布坐标（逆矩阵）
    final centerCanvas = MatrixUtilsX.screenToCanvas(centerScreen, matrix);

    // 计算新矩阵：围绕画布中心缩放
    final newMatrix = matrix.clone()
      ..translateByVector3(Vector3(centerCanvas.dx, centerCanvas.dy, 0))
      ..scaleByVector3(Vector3(trueScale, trueScale, 1))
      ..translateByVector3(Vector3(-centerCanvas.dx, -centerCanvas.dy, 0));

    // 最终统一更新（回调 + 重置）
    restoreMatrix(newMatrix);
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
  void resetMatrix(CanvasModel model) {
    final containerHeight =
        ScreenTools.screenHeight -
        ScreenTools.statusBarHeight -
        ScreenTools.bottomBarHeight -
        117.w;
    final containerWidth = ScreenTools.screenWidth;

    final scaleW = containerWidth / model.width;
    final scaleH = containerHeight / model.height;
    final double minScale = math.min(scaleW, scaleH);

    final double displayWidth = model.width * minScale;
    final double displayHeight = model.height * minScale;
    final double offsetX = (containerWidth - displayWidth) / 2.0;
    final double offsetY = (containerHeight - displayHeight) / 2.0;

    matrix = Matrix4.identity()
      ..scaleByVector3(Vector3(1.0, 1.0, 1))
      ..translateByVector3(Vector3(offsetX, offsetY, 0));

    _reset();
    onMatrixChanged?.call(matrix.clone(), 1.0, Offset(offsetX, offsetY));
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

  void updateModelMatrix4(Size canvasSize, Size constraintsSize, double scale) {
    final scaleW = constraintsSize.width / canvasSize.width;
    final scaleH = constraintsSize.height / canvasSize.height;
    final double minScale = math.min(scaleW, scaleH);

    final double displayWidth = canvasSize.width * minScale;
    final double displayHeight = canvasSize.height * minScale;
    final double offsetX = (constraintsSize.width - displayWidth) / 2.0;
    final double offsetY = (constraintsSize.height - displayHeight) / 2.0;

    Matrix4 matrix = Matrix4.identity()
      ..scaleByVector3(Vector3(scale, scale, 1))
      ..translateByVector3(Vector3(offsetX, offsetY, 0));

    onMatrixChanged?.call(matrix.clone(), scale, Offset(offsetX, offsetY));
  }
}
