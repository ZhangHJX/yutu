import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import './text_widget/text_property_widget.dart';
import './text_widget/color_effect_widget.dart';
import './text_widget/spacing_alignment_widget.dart';

class TextPropertyDialog extends StatefulWidget {
  final VoidCallback? onDeleteText;
  final dynamic element; // EditBoxData from create_design_model
  final Function(bool notify)? onPropertyChanged; // 属性改变时的回调

  const TextPropertyDialog({
    super.key,
    this.onDeleteText,
    this.element,
    this.onPropertyChanged,
  });

  @override
  State<TextPropertyDialog> createState() => _TextPropertyDialogState();
}

class _TextPropertyDialogState extends State<TextPropertyDialog>
    with SingleTickerProviderStateMixin {
  // TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 使用 KeyboardDismissOnTap 包裹，点击外部可关闭键盘
    return KeyboardDismissOnTap(
      // ⭐ 使用 KeyboardVisibilityBuilder 监听键盘状态
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Container(
            width: ScreenTools.screenWidth,
            margin: EdgeInsets.only(
              bottom: ScreenTools.getKeyboardHeight(context, isKeyboardVisible),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.w),
                topRight: Radius.circular(18.w),
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min, // ⭐ 关键：自适应高度
                  children: [
                    // 标题栏
                    _buildTitleBarWithTabs(),

                    // ⭐ 使用 AnimatedSize 实现高度变化动画
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          return _buildCurrentTabContent(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ⭐ 新增方法：根据当前索引返回对应的内容
  Widget _buildCurrentTabContent(BuildContext context) {
    switch (_tabController.index) {
      case 0:
        return SingleChildScrollView(
          child: TextPropertyWidget(
            element: widget.element,
            onPropertyChanged: widget.onPropertyChanged,
            onDeleteText: widget.onDeleteText,
            onFontChanged: (fontFamily, fontSize, fontWeight) {
              final data = widget.element;
              data.fontFamily = fontFamily;
              data.fontSize = double.tryParse(fontSize) ?? 16.0;
              data.fontWeight = fontWeight;
              widget.onPropertyChanged?.call(true);
            },
            onColorChanged: (color) {
              // 这个回调在 TextPropertyWidget 中暂时不需要，因为颜色在颜色效果标签页
            },
          ),
        );
      case 1:
        return SingleChildScrollView(
          child: ColorEffectWidget(
            element: widget.element,
            onPropertyChanged: widget.onPropertyChanged,
            onColorEffectChanged:
                (
                  textColor,
                  textAlpha,
                  borderColor,
                  borderWidth,
                  borderAlpha,
                  shadowEnabled,
                  shadowColor,
                  shadowX,
                  shadowY,
                  shadowBlur,
                  shawAlpha,
                ) {
                  final data = widget.element;
                  data.textColor = textColor;
                  data.textAlpha = textAlpha;
                  data.borderColor = borderColor;
                  data.borderWidth = borderWidth;
                  data.borderAlpha = borderAlpha;
                  data.isShawOpen = shadowEnabled;
                  data.shawColor = shadowColor;
                  data.shawX = shadowX;
                  data.shawY = shadowY;
                  data.blurValue = shadowBlur;
                  data.shawAlpha = shawAlpha;
                  widget.onPropertyChanged?.call(true);
                },
          ),
        );
      case 2:
        return SingleChildScrollView(
          child: SpacingAlignmentWidget(
            element: widget.element,
            onPropertyChanged: widget.onPropertyChanged,
            onSpacingAlignmentChanged: (lineHeight, letterSpacing, textAlign) {
              final data = widget.element;
              data.lineHeight = lineHeight;
              data.fontSpace = letterSpacing;
              data.align = textAlign;
              widget.onPropertyChanged?.call(true);
            },
          ),
        );
      default:
        return SingleChildScrollView(
          child: TextPropertyWidget(
            element: widget.element,
            onPropertyChanged: widget.onPropertyChanged,
            onDeleteText: widget.onDeleteText,
            onFontChanged: (fontFamily, fontSize, fontWeight) {
              final data = widget.element;
              data.fontFamily = fontFamily;
              data.fontSize = double.tryParse(fontSize) ?? 16.0;
              data.fontWeight = fontWeight;
              widget.onPropertyChanged?.call(true);
            },
            onColorChanged: (color) {},
          ),
        );
    }
  }

  // 标题栏
  Widget _buildTitleBarWithTabs() {
    return Container(
      width: ScreenTools.screenWidth,
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: ScreenTools.screenWidth - 110.w,
            height: 50.w,
            padding: EdgeInsets.only(left: 20.w, top: 10.w),
            child: TabBar(
              controller: _tabController,
              labelColor: "#ff262626".color,
              unselectedLabelColor: "#ff262626".color.withValues(alpha: 0.6),
              labelStyle: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w600,
              ),
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              indicatorPadding: EdgeInsets.zero,
              tabs: [
                Container(
                  width: 70.w,
                  color: Colors.white,
                  child: Tab(text: '字体属性'),
                ),
                Container(
                  width: 70.w,
                  color: Colors.white,
                  child: Tab(text: '颜色效果'),
                ),
                Container(
                  width: 70.w,
                  color: Colors.white,
                  child: Tab(text: '行距对齐'),
                ),
              ],
            ),
          ),

          Spacer(),

          // 关闭按钮
          GestureDetector(
            onTap: () {
              SmartDialog.dismiss();
            },
            child: Container(
              margin: EdgeInsets.only(top: 10.w),
              width: 35.w,
              height: 35.w,
              child: Center(
                child: Image.asset(
                  'assets/images/canvals/canvals_close_icon.png',
                  width: 12.w,
                  height: 12.w,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
        ],
      ),
    );
  }
}
