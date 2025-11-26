import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../utils/index.dart';

/// 全局选择状态管理控制器
/// 负责管理当前选中的文本框ID，确保只有一个文本框处于选中状态
class CanvalsController extends GetxController {
  PointerEvent? currentPoint; // 画布点击
  Size canvalsSize = Size.zero; //画布大小

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
  Rxn<AssetEntity> selectedAsset = Rxn<AssetEntity>();

  Offset center = Offset.zero;

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

  /// 清除添加标记
  void clearAddFlag() {
    _shouldAdd.value = false;
  }

  /// 清除添加图片标记
  void clearAddImageFlag() {
    _shouldAddImage.value = false;
    selectedAsset.value = null;
  }

  /// 清除删除标记
  void clearDeleteFlag() {
    _shouldDelete.value = false;
  }

  /// 标记需要添加新的图片元素
  void addNewImage(AssetEntity assetEntity, {Offset? targetCenter}) {
    if (targetCenter != null) {
      center = targetCenter;
    }
    selectedAsset.value = assetEntity;
    _shouldAddImage.value = true;
  }
}
