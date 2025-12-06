import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../../widgets/gradient_text.dart';
import 'save_logic.dart';

class CanvalsSaveTemplateDialog extends StatelessWidget {
  CanvalsSaveTemplateDialog({super.key});
  final logic = Get.put(SaveLogic());

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
                  child: Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          // 滚动时关闭下拉列表
                          if (notification is ScrollUpdateNotification &&
                              logic.showScenarioDropdown.value) {
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
                                label: '*模版描述',
                                controller: logic.descriptionController,
                                hintText: '输入模版描述',
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

                      // 下拉列表 - 浮动在弹框上方
                      Obx(() {
                        return logic.showScenarioDropdown.value
                            ? Positioned(
                                left: 16.w,
                                right: 16.w,
                                top: 250.w, // 应用场景输入框下方位置
                                child: Material(
                                  elevation: 8.w,
                                  borderRadius: BorderRadius.circular(12.w),
                                  child: Container(
                                    color: Colors.white,

                                    constraints: BoxConstraints(
                                      maxHeight: 200.w, // 限制最大高度
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.w),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: logic.scenarios.map((
                                          scenario,
                                        ) {
                                          return GestureDetector(
                                            onTap: () {
                                              logic.selectScenario(scenario);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 12.w,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    logic
                                                            .selectedScenario
                                                            .value ==
                                                        scenario
                                                    ? "#DCEDFE".color
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8.w),
                                              ),
                                              child: Text(
                                                scenario,
                                                style: TextStyle(
                                                  fontSize: 14.w,
                                                  color:
                                                      logic
                                                              .selectedScenario
                                                              .value ==
                                                          scenario
                                                      ? "#3C7BFF".color
                                                      : "#727272".color,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }),
                    ],
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

        GestureDetector(
          onTap: logic.toggleScenarioDropdown,
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
                  logic.selectedScenario.value,
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
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '*风格标签',
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
        Wrap(
          spacing: 8.w,
          runSpacing: 8.w,
          children: logic.suggestedTags.map((tag) {
            return GestureDetector(
              onTap: () => logic.toggleTag(tag),
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
                  tag,
                  colors: [
                    Color(0xFFC86CFF), // #C86CFF
                    Color(0xFF5B98FF), // #5B98FF
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  style: TextStyle(fontSize: 12.w, fontWeight: FontWeight.w500),
                ),
              ),
            );
          }).toList(),
        ),

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
                      children: logic.selectedTags.map((tag) {
                        return GestureDetector(
                          onTap: () => logic.removeTag(tag),
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
                                  tag,
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
                                child: Container(
                                  width: 10.w,
                                  height: 10.w,
                                  color: "#ff909090".color,
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
              Expanded(
                child: GestureDetector(
                  onTap: logic.saveTemplate,
                  child: Image.asset(
                    'assets/images/canvals/canvals_save_icon.png',
                    width: 153.w,
                    height: 40.w,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 底部安全区域
        SizedBox(height: ScreenTools.bottomBarHeight),
      ],
    );
  }
}
