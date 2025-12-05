import 'package:common/common.dart';
import 'package:flutter/material.dart';

class SaveLogic extends GetxController {
  // 文本控制器
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final scenarioDropdownKey = GlobalKey();

  // 状态
  final selectedTags = <String>[].obs;
  final showScenarioDropdown = false.obs;
  final selectedScenario = '房间宣传'.obs;

  // 常量数据
  List<String> scenarios = [
    '房间宣传',
    '活动公告',
    '歌单展示',
    '名片模板',
    '节日氛围',
    '冠歌卡',
    '冠名卡',
  ];

  final List<String> suggestedTags = [
    '二次元',
    '恋爱',
    '简约',
    '炫彩',
    '可爱',
    '赛博',
    '复古',
  ];

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// 切换标签选择状态
  void toggleTag(String tag) {
    if (!selectedTags.contains(tag)) {
      selectedTags.add(tag);
    }
  }

  /// 移除标签
  void removeTag(String tag) {
    debugPrint("--移除标签---");
    selectedTags.remove(tag);
  }

  /// 切换场景下拉框显示状态
  void toggleScenarioDropdown() {
    FocusManager.instance.primaryFocus?.unfocus(); // 先收起键盘
    showScenarioDropdown.value = !showScenarioDropdown.value;
  }

  /// 关闭场景下拉框
  void closeScenarioDropdown() {
    showScenarioDropdown.value = false;
  }

  /// 选择场景
  void selectScenario(String scenario) {
    selectedScenario.value = scenario;
    showScenarioDropdown.value = false;
  }

  /// 保存为草稿
  void saveAsDraft() {
    debugPrint("保存为草稿");
    // TODO: 实现保存为草稿的逻辑
  }

  /// 保存模版
  void saveTemplate() {
    if (titleController.text.trim().isEmpty) {
      SmartDialog.showToast('请输入模版标题');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      SmartDialog.showToast('请输入模版描述');
      return;
    }

    if (selectedTags.isEmpty) {
      SmartDialog.showToast('请至少选择一个风格标签');
      return;
    }

    // TODO: 实现保存逻辑
    debugPrint('保存模版:');
    debugPrint('标题: ${titleController.text}');
    debugPrint('描述: ${descriptionController.text}');
    debugPrint('场景: ${selectedScenario.value}');
    debugPrint('标签: ${selectedTags.toList()}');

    SmartDialog.showToast('模版保存成功');
    SmartDialog.dismiss();
  }
}
