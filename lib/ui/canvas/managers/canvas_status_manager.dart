import 'package:flutter/material.dart';

/// 画布平移和缩放手势管理器
/// 负责处理画布的拖动和缩放操作
class CanvasStatusManager {
  // 画布变换状态
  double _scale = 1.0; // 画布缩放比例
  Offset _offset = Offset.zero; // 画布偏移量

  // 上一次的缩放和偏移量
  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;

  // 缩放限制（25% - 300%）
  static const double minScale = 0.25;
  static const double maxScale = 3.0;

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

  // 回调函数
  void Function(Offset offset, double scale)? onTransformChanged;

  // ============================================================
  // GestureDetector 版本的缩放/平移（推荐使用）
  // ============================================================

  /// 手势开始（单指 / 双指均会触发）
  void onScaleStart(Offset focalPoint) {
    _previousScale = _scale;
    _previousOffset = _offset;
  }

  /// 手势更新（单指拖动 + 双指缩放都走这里）
  /// [scale] 为 GestureDetector 提供的累计缩放因子（相对于手势开始时）
  /// [focalPoint] 为当前所有触点的中点（屏幕坐标）
  void onScaleUpdate(double scale, Offset focalPoint) {
    // 计算新的缩放
    _scale = (_previousScale * scale).clamp(minScale, maxScale);

    // 使用“当前”两指中点作为锚点：
    // 先根据【手势开始时】的变换，求出当前 focalPoint 对应的画布坐标，
    // 再用新的 _scale 反推偏移，使该画布点仍然落在当前 focalPoint 上。
    final canvasPoint = (focalPoint - _previousOffset) / _previousScale;
    _offset =
        focalPoint - Offset(canvasPoint.dx * _scale, canvasPoint.dy * _scale);

    _notifyTransformChanged();
  }

  /// 通知变换改变
  void _notifyTransformChanged() {
    onTransformChanged?.call(_offset, _scale);
  }

  /// 手势结束
  void onScaleEnd() {
    // _resetInteractionState();
  }

  /// 重置画布变换
  void reset() {
    _offset = Offset.zero;
    _scale = 1.0;
    _notifyTransformChanged();
  }

  /// 设置画布变换
  void setTransform(Offset offset, double scale) {
    _offset = offset;
    _scale = scale.clamp(minScale, maxScale);
    _notifyTransformChanged();
  }

  /// 放大画布（每次增加10%）
  void zoomIn() {
    _scale = (_scale * 1.2).clamp(minScale, maxScale);
    _notifyTransformChanged();
  }

  /// 缩小画布（每次减少10%）
  void zoomOut() {
    _scale = (_scale / 1.1).clamp(minScale, maxScale);
    _notifyTransformChanged();
  }
}
