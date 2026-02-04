import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:voicetemplate/pages/canvas/draft/index.dart';
import '../model/index.dart';
import '../history/clone_tools/canvas_model_clone.dart';
import 'dart:math' as math;
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/core/index.dart';

/// 全局选择状态管理控制器： 负责管理当前选中的文本框ID、画布模型以及元素列表
class CanvalsController extends GetxController with WidgetsBindingObserver {
  final global = Get.find<GlobalLogic>();

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

  final canPop = false.obs;
  PointerEvent? currentPoint; // 画布点击
  final RxList<CanvasElement> elements = <CanvasElement>[].obs;

  /// 草稿保存处理
  Timer? _saveDebounceTimer;
  int _lastSaveTime = 0;
  static const int _minSaveIntervalMs = 2000; // 2秒

  @override
  void onClose() {
    _saveDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // 如果画布模型中已经包含元素（例如从草稿恢复），将其同步到响应式列表
    if (canvasModel.elements.isNotEmpty) {
      elements.assignAll(canvasModel.elements);
      canvasModel.elements = elements;
    } else {
      // 确保模型中的元素列表引用响应式列表，便于后续保存快照
      canvasModel.elements = elements;
    }
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

  // UUID生成器
  final Uuid _uuid = const Uuid();

  /// 获取当前选中的ID
  String get selectedId => _selectedId.value;

  /// 获取删除标记
  bool get shouldDelete => _shouldDelete.value;

  // 图片相关操作
  final RxBool _shouldAddImage = false.obs;
  bool get shouldAddImage => _shouldAddImage.value;
  final RxList<PickerInfoModel> _pendingImageList = <PickerInfoModel>[].obs;
  List<PickerInfoModel> get pendingImageList => _pendingImageList.toList();

  /// 检查指定ID是否被选中
  bool isSelected(String id) => _selectedId.value == id;

  /// 获取画布的中心
  ///
  Offset get canvalsCenter => Offset(canvalsWidth / 2, canvalsHeight / 2);

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

  /// 清除添加图片标记
  void clearAddImageFlag() {
    _shouldAddImage.value = false;
    _pendingImageList.clear();
  }

  /// 清除删除标记
  void clearDeleteFlag() {
    _shouldDelete.value = false;
  }

  /// 标记需要添加多张图片（一次选择多张时使用，不会互相覆盖）
  void addNewImages(List<PickerInfoModel> list) {
    _pendingImageList.assignAll(list);
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

  void enableBack() => canPop.value = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveCanvasWithDebounce();
    }
  }

  /// 防抖保存画布截图（避免频繁保存）
  void _saveCanvasWithDebounce() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // 检查距离上次保存是否超过最小间隔
    if (now - _lastSaveTime < _minSaveIntervalMs) {
      AppLogger.info('=距离上次保存时间过短，跳过本次保存=');
      return;
    }

    // 取消之前的定时器
    _saveDebounceTimer?.cancel();

    // 设置新的定时器，延迟 500ms 保存
    // 如果在这期间又触发了，会取消并重新计时
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      // 再次检查时间间隔（防止定时器执行时已经超过间隔）
      if (currentTime - _lastSaveTime >= _minSaveIntervalMs) {
        _lastSaveTime = currentTime;
        AppLogger.info('=开始保存画布截图=');
        DraftManager().saveCurrentCanvals();
      } else {
        AppLogger.info('=定时器执行时发现时间间隔不足，跳过保存=');
      }
    });
  }
}
