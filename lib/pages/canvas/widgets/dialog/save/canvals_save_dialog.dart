import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../../../widgets/gradient_text.dart';
import 'dart:typed_data';
import 'save_logic.dart';

class CanvalsSaveTemplateDialog extends StatefulWidget {
  final Future<Uint8List?> Function()? handleImageCallBack;

  const CanvalsSaveTemplateDialog({super.key, this.handleImageCallBack});

  @override
  State<CanvalsSaveTemplateDialog> createState() =>
      _CanvalsSaveTemplateDialogState();
}

class _CanvalsSaveTemplateDialogState extends State<CanvalsSaveTemplateDialog> {
  final logic = Get.put(SaveLogic(), tag: saveDialog);
  // 用于定位下拉列表的目标组件
  final GlobalKey _scenarioDropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadCanvalsImage();
  }

  void loadCanvalsImage() async {
    if (widget.handleImageCallBack != null) {
      logic.canvalsImage = await widget.handleImageCallBack!();
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<SaveLogic>(tag: saveDialog)) {
      Get.delete<SaveLogic>(tag: saveDialog, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 使用 KeyboardDismissOnTap 包裹，点击外部可关闭键盘
    return KeyboardDismissOnTap(
      // ⭐ 使用 KeyboardVisibilityBuilder 监听键盘状态
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          // 键盘弹出时关闭下拉列表
          if (isKeyboardVisible && logic.showScenarioDropdown.value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SmartDialog.dismiss(tag: 'scenario_dropdown');
              logic.closeScenarioDropdown();
            });
          }
          // 根据键盘是否可见动态计算底部边距
          final keyboardHeight = isKeyboardVisible
              ? MediaQuery.of(context).viewInsets.bottom
              : 0.0;

          return Container(
            // ⭐ 动态调整底部边距，避免被键盘遮挡
            margin: EdgeInsets.only(bottom: keyboardHeight),
            height: ScreenTools.screenHeight - 195.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.w),
                topRight: Radius.circular(18.w),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 中间标题
                    Center(
                      child: Container(
                        padding: EdgeInsets.only(top: 19.w, bottom: 20.w),
                        child: Text(
                          '保存模版',
                          style: TextStyle(
                            fontSize: 18.w,
                            fontWeight: FontWeight.w500,
                            color: "#FF262626".color,
                          ),
                        ),
                      ),
                    ),

                    // 右侧"保存为草稿"
                    Positioned(
                      right: 16.w,
                      child: GestureDetector(
                        onTap: logic.saveAsDraft,
                        child: Text(
                          '保存为草稿',
                          style: TextStyle(
                            fontSize: 13.w,
                            color: "#6C64FF".color, // 你设计稿的紫色
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.w),

                // 可滚动的内容区域
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // 滚动时关闭下拉列表
                      if (notification is ScrollUpdateNotification &&
                          logic.showScenarioDropdown.value) {
                        SmartDialog.dismiss(tag: 'scenario_dropdown');
                        logic.closeScenarioDropdown();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(left: 16.w, right: 16.w),
                      child: Column(
                        children: [
                          // 模版标题
                          _buildInputField(
                            label: '*模版标题',
                            controller: logic.titleController,
                            hintText: '输入模版标题',
                          ),

                          SizedBox(height: 12.w),

                          // 模版描述
                          _buildInputField(
                            label: '模版描述',
                            controller: logic.descriptionController,
                            hintText: '输入模版描述(可选填)',
                          ),

                          SizedBox(height: 12.w),

                          // 应用场景
                          _buildScenarioDropdown(),

                          SizedBox(height: 12.w),

                          // 风格标签
                          _buildTagsSection(),

                          SizedBox(height: 9.w),
                        ],
                      ),
                    ),
                  ),
                ),

                // 底部按钮
                _buildBottomButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.w,
            fontWeight: FontWeight.w500,
            color: "#FF3E3E3E".color,
          ),
        ),

        SizedBox(height: 2.w),

        Container(
          height: 50.w,
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.w),
            border: Border.all(color: "#FFE6E6E6".color, width: 1.w),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: "#ff6C6C6C".color, fontSize: 14.w),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '*应用场景',
          style: TextStyle(
            fontSize: 16.w,
            fontWeight: FontWeight.w500,
            color: "#FF3E3E3E".color,
          ),
        ),

        SizedBox(height: 2.w),

        Obx(() {
          return GestureDetector(
            key: _scenarioDropdownKey,
            onTap: () => _showScenarioDropdown(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.w),
                border: Border.all(color: "#FFE6E6E6".color, width: 1.w),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.w),
              margin: EdgeInsets.only(right: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    logic.sceneName.value,
                    style: TextStyle(
                      fontSize: 14.w,
                      color: "#FF242424".color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    logic.showScenarioDropdown.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20.w,
                    color: "#ff111111 ".color,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 使用 SmartDialog.showAttach 显示下拉列表
  void _showScenarioDropdown() {
    FocusManager.instance.primaryFocus?.unfocus(); // 先收起键盘

    if (logic.showScenarioDropdown.value) {
      // 如果已经显示，则关闭
      SmartDialog.dismiss(tag: 'scenario_dropdown');
      logic.closeScenarioDropdown();
    } else {
      // 显示下拉列表
      logic.showScenarioDropdown.value = true;

      SmartDialog.showAttach(
        targetContext: _scenarioDropdownKey.currentContext!,
        alignment: Alignment.bottomCenter,
        animationType: SmartAnimationType.centerFade_otherSlide,
        animationTime: Duration(milliseconds: 200),
        maskColor: Colors.transparent,
        clickMaskDismiss: true,
        tag: 'scenario_dropdown',
        builder: (dialogContext) => Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
            width: ScreenTools.screenWidth - 32.w,
            constraints: BoxConstraints(
              maxHeight: 200.w, // 限制最大高度
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: "#CDE4FF".color,
                  blurRadius: 5.w,
                  spreadRadius: 0,
                  offset: Offset(0, 1.w),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: logic.scenarios.map((model) {
                  return GestureDetector(
                    onTap: () {
                      logic.selectScenario(model.name);
                      SmartDialog.dismiss(tag: 'scenario_dropdown');
                    },
                    child: Obx(
                      () => Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: logic.sceneName.value == model.name
                              ? "#DCEDFE".color
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Text(
                          model.name,
                          style: TextStyle(
                            fontSize: 14.w,
                            color: logic.sceneName.value == model.name
                                ? "#3C7BFF".color
                                : "#727272".color,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ).then((_) {
        // 当对话框关闭时，更新状态
        logic.closeScenarioDropdown();
      });
    }
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '风格标签',
              style: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w500,
                color: "#FF3E3E3E".color,
              ),
            ),
            Text(
              '(可多选)',
              style: TextStyle(
                fontSize: 13.w,
                fontWeight: FontWeight.w500,
                color: "#FF007BFE".color,
              ),
            ),
          ],
        ),

        SizedBox(height: 10.w),

        // 建议标签
        Obx(() {
          return Wrap(
            spacing: 8.w,
            runSpacing: 8.w,
            children: logic.suggestedTags.map((model) {
              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus(); // 先收起键盘
                  logic.toggleTag(model);
                },
                child: Container(
                  padding: EdgeInsets.only(
                    left: 9.5.w,
                    right: 9.w,
                    top: 5.w,
                    bottom: 5.w,
                  ),
                  decoration: BoxDecoration(
                    color: "#FFF0F0F0".color,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: GradientText(
                    model.name,
                    colors: [
                      Color(0xFFC86CFF), // #C86CFF
                      Color(0xFF5B98FF), // #5B98FF
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    style: TextStyle(
                      fontSize: 12.w,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),

        SizedBox(height: 13.w),

        // 已选标签显示
        Container(
          height: 104.w,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.w),
            border: Border.all(color: "#FFE6E6E6".color, width: 1.w),
          ),
          child: Obx(
            () => logic.selectedTags.isNotEmpty
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 7.w,
                    ),
                    child: Wrap(
                      spacing: 10.w,
                      runSpacing: 10.w,
                      children: logic.selectedTags.map((model) {
                        return GestureDetector(
                          onTap: () => logic.removeTag(model),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  left: 10.w,
                                  right: 10.w,
                                  top: 5.w,
                                  bottom: 5.w,
                                ),
                                decoration: BoxDecoration(
                                  color: "#FFF0F0F0".color,
                                  borderRadius: BorderRadius.circular(12.w),
                                ),
                                child: GradientText(
                                  model.name,
                                  colors: [
                                    Color(0xFFC86CFF), // #C86CFF
                                    Color(0xFF5B98FF), // #5B98FF
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  style: TextStyle(
                                    fontSize: 12.w,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2.5.w,
                                top: -2.5.w,
                                child: Image.asset(
                                  'assets/images/canvals/canvals_fenge_close.png',
                                  width: 10.w,
                                  height: 10.w,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 25.w, top: 26.w, right: 24.w),
          height: 66.w,
          child: Row(
            children: [
              // 取消按钮
              Expanded(
                child: GestureDetector(
                  onTap: () => SmartDialog.dismiss(),
                  child: Image.asset(
                    'assets/images/canvals/canvals_cancel_icon.png',
                    width: 153.w,
                    height: 40.w,
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              SizedBox(width: 20.w),

              // 保存按钮
              Obx(() {
                return Expanded(
                  child: GestureDetector(
                    onTap: logic.saveTemplate,
                    child: Image.asset(
                      'assets/images/canvals/${logic.isCanSave.value ? 'canvals_save_icon' : 'canvals_no_save'}.png',
                      width: 153.w,
                      height: 40.w,
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // 底部安全区域
        SizedBox(height: ScreenTools.bottomBarHeight),
      ],
    );
  }
}
