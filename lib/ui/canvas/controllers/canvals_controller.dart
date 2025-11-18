import 'package:common/common.dart';
import 'package:uuid/uuid.dart';
import '../utils/handle_select_images.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';

/// 全局选择状态管理控制器
/// 负责管理当前选中的文本框ID，确保只有一个文本框处于选中状态
class CanvalsController extends GetxController {
  final selectImageHelper = SelectImageHelper(maxCount: 1);

  //激活卡片
  final RxBool _showToolbar = false.obs;
  void updateToolBar(bool newVal) {
    _showToolbar.value = newVal;
  }

  bool get showToolbar => _showToolbar.value;

  // 当前选中的文本框ID
  final RxString _selectedId = ''.obs;

  // 删除标记
  final RxBool _shouldDelete = false.obs;

  // 添加标记
  final RxBool _shouldAdd = false.obs;

  // 添加图片标记
  final RxBool _shouldAddImage = false.obs;
  final RxString _imagePath = ''.obs;

  // UUID生成器
  final Uuid _uuid = const Uuid();

  /// 获取当前选中的ID
  String get selectedId => _selectedId.value;

  /// 获取当前选中ID的响应式流
  RxString get selectedIdStream => _selectedId;

  /// 获取删除标记
  bool get shouldDelete => _shouldDelete.value;

  /// 获取添加标记
  bool get shouldAdd => _shouldAdd.value;

  /// 获取添加图片标记
  bool get shouldAddImage => _shouldAddImage.value;

  /// 获取图片路径
  String get imagePath => _imagePath.value;

  /// 检查指定ID是否被选中
  bool isSelected(String id) => _selectedId.value == id;

  /// 选中指定ID的文本框
  void select(String id) {
    if (_selectedId.value != id) {
      _selectedId.value = id;
    }
  }

  /// 取消选中（清空选择）
  void deselect() {
    _selectedId.value = '';
  }

  /// 生成新的唯一ID
  String generateId() => _uuid.v4();

  /// 切换选择状态：如果已选中则取消，否则选中
  void toggleSelection(String id) {
    if (isSelected(id)) {
      deselect();
    } else {
      select(id);
    }
  }

  /// 标记需要删除当前选中的文本框
  void deleteSelected() {
    if (_selectedId.value.isNotEmpty) {
      _shouldDelete.value = true;
    }
  }

  /// 标记需要添加新的文本框
  void addNewBox() {
    _shouldAdd.value = true;
  }

  /// 标记需要添加新的图片元素
  void addNewImage(String imagePath) {
    _imagePath.value = imagePath;
    _shouldAddImage.value = true;
  }

  /// 清除添加标记
  void clearAddFlag() {
    _shouldAdd.value = false;
  }

  /// 清除添加图片标记
  void clearAddImageFlag() {
    _shouldAddImage.value = false;
    _imagePath.value = '';
  }

  /// 清除删除标记
  void clearDeleteFlag() {
    _shouldDelete.value = false;
  }

  // 画布相关
  final scale = 1.0.obs;
  final offset = Offset.zero.obs;

  // --- 手势基线 ---
  double startScale = 1;
  Offset startOffset = Offset.zero;

  Matrix4 get matrix => Matrix4.identity()
    ..translateByVector3(Vector3(offset.value.dx, offset.value.dy, 0))
    ..scaleByVector3(Vector3(scale.value, scale.value, scale.value));

  void onScaleStart() {
    startScale = scale.value;
    startOffset = offset.value;
  }

  void onScale(double scaleDelta, Offset focal) {
    final newScale = startScale * scaleDelta;
    scale.value = newScale;

    // 保持焦点
    final Matrix4 invOld = Matrix4.inverted(matrix);
    final focalOld = _transform(invOld, focal);

    final Matrix4 newMatrix = Matrix4.identity()
      ..translateByVector3(Vector3(offset.value.dx, offset.value.dy, 0))
      ..scaleByVector3(Vector3(scale.value, scale.value, scale.value));

    final Matrix4 invNew = Matrix4.inverted(newMatrix);
    final focalNew = _transform(invNew, focal);

    offset.value += (focalNew - focalOld);
  }

  void onPan(Offset delta) {
    offset.value += delta;
  }

  Offset _transform(Matrix4 m, Offset p) {
    final v = m.transform3(Vector3(p.dx, p.dy, 0));
    return Offset(v.x, v.y);
  }

  // ============================================================
  // 逻辑坐标（画布坐标）转换
  // ============================================================

  Offset screenToCanvas(Offset screenPoint) {
    final inv = Matrix4.inverted(matrix);
    return _transform(inv, screenPoint);
  }

  Offset canvasToScreen(Offset canvasPoint) {
    final v = matrix.transform3(Vector3(canvasPoint.dx, canvasPoint.dy, 0));
    return Offset(v.x, v.y);
  }
}
