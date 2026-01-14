import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../model/index.dart';
import '../../history/clone_tools/canvas_model_clone.dart';
import 'dart:math' as math;

/// 全局选择状态管理控制器： 负责管理当前选中的文本框ID、画布模型以及元素列表
class CanvalsController extends GetxController {
  // 画布模型
  final args =
      (Get.arguments as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  CanvasModel get canvasModel {
    final model = args['model'];
    if (model is CanvasModel) {
      return model;
    }
    // 如果类型不匹配或不存在，返回默认的 CanvasModel
    return CanvasModel();
  }

  PageSource get type {
    final typeValue = args['type'];
    if (typeValue is PageSource) {
      return typeValue;
    }
    // 如果类型不匹配或不存在，返回默认值
    return PageSource.create;
  }

  int get isOwn {
    final value = args['is_own'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  PointerEvent? currentPoint; // 画布点击
  final RxList<CanvasElement> elements = <CanvasElement>[].obs;

  @override
  void onInit() {
    super.onInit();
    // 如果画布模型中已经包含元素（例如从草稿恢复），将其同步到响应式列表
    if (canvasModel.elements.isNotEmpty) {
      elements.assignAll(canvasModel.elements);
      canvasModel.elements = elements;
    } else {
      // 确保模型中的元素列表引用响应式列表，便于后续保存快照
      canvasModel.elements = elements;
    }
    debugPrint("--走过的路线---onInit---");
  }

  CanvasModel? buildSnapshot() {
    // 使用 JSON 序列化方式克隆画布模型
    final cloned = CanvasModelClone.clone(canvasModel);
    // 更新元素列表（因为 elements 是响应式列表，需要单独处理）
    cloned.elements = elements.toList();
    cloned.timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return cloned;
  }

  void addElement(CanvasElement element) {
    elements.add(element);
  }

  void removeElement(String id) {
    elements.removeWhere((element) => element.id == id);
  }

  void reorderElements(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= elements.length ||
        newIndex < 0 ||
        newIndex >= elements.length) {
      return;
    }
    final element = elements.removeAt(oldIndex);
    elements.insert(newIndex, element);
  }

  void refreshElements() => elements.refresh();

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

  // UUID生成器
  final Uuid _uuid = const Uuid();

  /// 获取当前选中的ID
  String get selectedId => _selectedId.value;

  /// 获取删除标记
  bool get shouldDelete => _shouldDelete.value;

  /// 获取添加标记
  bool get shouldAdd => _shouldAdd.value;

  // 图片相关操作
  final RxBool _shouldAddImage = false.obs;
  bool get shouldAddImage => _shouldAddImage.value;

  final RxString _filePath = ''.obs;
  String get filePath => _filePath.value;

  double imageWidth = 0.0;
  double imageHeight = 0.0;

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
    _filePath.value = '';
    imageWidth = 0.0;
    imageHeight = 0.0;
  }

  /// 清除删除标记
  void clearDeleteFlag() {
    _shouldDelete.value = false;
  }

  /// 标记需要添加新的图片元素
  void addNewImage(
    String filePath,
    double width,
    double height, {
    Offset? targetCenter,
  }) {
    if (targetCenter != null) {
      center = targetCenter;
    }
    imageWidth = width;
    imageHeight = height;
    _filePath.value = filePath;
    _shouldAddImage.value = true;
  }

  /// 画布尺寸转换工具类
  double canvalsWidth = 0.0;
  double canvalsHeight = 0.0;
  void getCanvalsSize(double availableWidth, double availableHeight) {
    final scaleW = availableWidth / canvasModel.width;
    final scaleH = availableHeight / canvasModel.height;
    final double minScale = math.min(scaleW, scaleH);
    canvalsWidth = canvasModel.width * minScale;
    canvalsHeight = canvasModel.height * minScale;
  }
}
