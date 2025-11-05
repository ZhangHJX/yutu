import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../../widgets/gradient_text.dart';

class CanvalsSaveTemplateDialog extends StatefulWidget {
  const CanvalsSaveTemplateDialog({super.key});

  @override
  State<CanvalsSaveTemplateDialog> createState() =>
      _CanvalsSaveTemplateDialogState();
}

class _CanvalsSaveTemplateDialogState extends State<CanvalsSaveTemplateDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final GlobalKey _scenarioDropdownKey = GlobalKey();

  String _selectedScenario = '通知公告';
  final List<String> _selectedTags = [];
  bool _showScenarioDropdown = false;

  final List<String> _scenarios = [
    '通知公告',
    '活动宣传',
    '产品介绍',
    '节日祝福',
    '商务合作',
    '教育培训',
    '其他',
  ];

  final List<String> _suggestedTags = [
    '动漫',
    '恋爱',
    '简约',
    '活力',
    '赛博',
    '可爱',
    '复古',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 使用 KeyboardDismissOnTap 包裹，点击外部可关闭键盘
    return KeyboardDismissOnTap(
      // ⭐ 使用 KeyboardVisibilityBuilder 监听键盘状态
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          // 根据键盘是否可见动态计算底部边距
          final keyboardHeight = isKeyboardVisible
              ? MediaQuery.of(context).viewInsets.bottom
              : 0.0;

          return Stack(
            children: [
              // 主弹框内容
              Container(
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
                    // 标题
                    Container(
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

                    // 可滚动的内容区域
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(left: 16.w, right: 8.w),
                        child: Column(
                          children: [
                            // 模版标题
                            _buildInputField(
                              label: '*模版标题',
                              controller: _titleController,
                              hintText: '输入模版标题',
                            ),

                            SizedBox(height: 12.w),

                            // 模版描述
                            _buildInputField(
                              label: '*模版描述',
                              controller: _descriptionController,
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

                    // 底部按钮
                    _buildBottomButtons(),
                  ],
                ),
              ),

              // 下拉列表 - 浮动在弹框上方
              if (_showScenarioDropdown)
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  top: 310.w, // 应用场景输入框下方位置
                  child: Material(
                    elevation: 8.w,
                    borderRadius: BorderRadius.circular(8.w),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: 200.w, // 限制最大高度
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.w),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8.w,
                            offset: Offset(0, 2.w),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _scenarios.map((scenario) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedScenario = scenario;
                                  _showScenarioDropdown = false;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.w,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedScenario == scenario
                                      ? Colors.purple.shade50
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.w),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      scenario,
                                      style: TextStyle(
                                        fontSize: 14.w,
                                        color: _selectedScenario == scenario
                                            ? Colors.purple.shade700
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (_selectedScenario == scenario)
                                      Icon(
                                        Icons.check,
                                        size: 16.w,
                                        color: Colors.purple.shade700,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
          key: _scenarioDropdownKey,
          onTap: () {
            setState(() {
              _showScenarioDropdown = !_showScenarioDropdown;
            });
          },
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
                  _selectedScenario,
                  style: TextStyle(
                    fontSize: 14.w,
                    color: "#FF242424".color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _showScenarioDropdown
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
          children: _suggestedTags.map((tag) {
            // final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: Container(
                padding: EdgeInsets.only(
                  left: 9.5.w,
                  right: 9.w,
                  top: 5,
                  bottom: 5,
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

        // 已选标签输入框
        Container(
          margin: EdgeInsets.only(right: 8.w),
          height: 104.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.w),
            border: Border.all(color: "#FFE6E6E6".color, width: 1.w),
          ),
          child: Column(
            children: [
              // 已选标签显示
              if (_selectedTags.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  child: Wrap(
                    spacing: 10.w,
                    runSpacing: 10.w,
                    children: _selectedTags.map((tag) {
                      return Container(
                        height: 25.w,
                        width: 43.w,
                        decoration: BoxDecoration(
                          color: "#FFF0F0F0".color,
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        child: Stack(
                          children: [
                            Center(
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
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _removeTag(tag),
                                child: Icon(
                                  Icons.close,
                                  size: 10.w,
                                  color: "#ff909090".color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // 输入框
              TextField(
                controller: _tagsController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: '输入自定义标签',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.w,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.w,
                  ),
                ),
                onSubmitted: (value) {
                  // if (value.trim().isNotEmpty &&
                  //     !_selectedTags.contains(value.trim())) {
                  //   setState(() {
                  //     _selectedTags.add(value.trim());
                  //     _tagsController.clear();
                  //   });
                  // }
                },
              ),
            ],
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
                  onTap: _saveTemplate,
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

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _saveTemplate() {
    if (_titleController.text.trim().isEmpty) {
      SmartDialog.showToast('请输入模版标题');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      SmartDialog.showToast('请输入模版描述');
      return;
    }

    if (_selectedTags.isEmpty) {
      SmartDialog.showToast('请至少选择一个风格标签');
      return;
    }

    // TODO: 实现保存逻辑
    debugPrint('保存模版:');
    debugPrint('标题: ${_titleController.text}');
    debugPrint('描述: ${_descriptionController.text}');
    debugPrint('场景: $_selectedScenario');
    debugPrint('标签: $_selectedTags');

    SmartDialog.showToast('模版保存成功');
    SmartDialog.dismiss();
  }
}
