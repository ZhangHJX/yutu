import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../utils/index.dart';
import './widgets/slider_input_field.dart';
import '../../model/index.dart';

class CanvalsPropertyDialog extends StatefulWidget {
  final CanvasModel? canvasModel;
  final Function(bool notify)? onPropertyChanged; // 属性改变时的回调

  const CanvalsPropertyDialog({
    super.key,
    this.canvasModel,
    this.onPropertyChanged,
  });

  @override
  State<CanvalsPropertyDialog> createState() => _CanvalsPropertyDialogState();
}

class _CanvalsPropertyDialogState extends State<CanvalsPropertyDialog>
    with SingleTickerProviderStateMixin {
  // 填充相关属性
  String _fillColor = '#FFFFFF';
  final TextEditingController _canvalsFillColorController =
      TextEditingController(text: '#FFFFFF');
  double _fillAlpha = 1;

  @override
  void initState() {
    super.initState();
    _initializeFromModel();
  }

  /// 从模型初始化UI状态
  void _initializeFromModel() {
    if (widget.canvasModel == null) return;
    final props = widget.canvasModel!;

    _fillColor = props.fillColor;
    _fillAlpha = props.fillAlpha;
  }

  @override
  void dispose() {
    _canvalsFillColorController.dispose();
    super.dispose();
  }

  /// 打开颜色选择器
  void _openColorPicker({
    required Color initialColor,
    required ValueChanged<Color> onColorSelected,
    required BuildContext context,
  }) async {
    final selectedColor = await showColorPickerDialog(
      context,
      initialColor: initialColor,
    );

    if (selectedColor != null) {
      onColorSelected(selectedColor);
    }
  }

  /// 更新数据模型
  void _updateModel({bool notify = true}) {
    if (widget.canvasModel == null) return;
    final props = widget.canvasModel!;
    props.fillColor = _fillColor;
    props.fillAlpha = _fillAlpha;
    widget.onPropertyChanged?.call(notify);
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
            height: ScreenTools.bottomBarHeight + 235.w,
            margin: EdgeInsets.only(
              bottom: ScreenTools.getKeyboardHeight(context, isKeyboardVisible),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.w),
                topRight: Radius.circular(18.w),
              ),
              boxShadow: [
                BoxShadow(
                  color: "#CDE4FF".color,
                  offset: Offset(0, 1),
                  blurRadius: 5,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ⭐ 关键：自适应高度
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.only(bottom: 15.w),
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 17.w),
                          child: Text(
                            '画布属性',
                            style: TextStyle(
                              fontSize: 18.w,
                              fontWeight: FontWeight.w500,
                              color: "#ff262626".color,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 10.w,
                        top: 12.w,
                        child: GestureDetector(
                          onTap: () {
                            SmartDialog.dismiss();
                          },
                          child: SizedBox(
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
                      ),
                    ],
                  ),
                ),

                // 内容区域
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 5.w,
                  ),
                  child: Column(
                    children: [
                      // 填充区域
                      _buildFillSection(context),
                      SizedBox(height: 9.w),
                      _buildFillAlphaSection(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFillSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '填充',
          style: TextStyle(
            fontSize: 13.w,
            color: "#ff3E3E3E ".color.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
        ),

        SizedBox(height: 6.w),

        // 颜色预览和输入框
        Row(
          children: [
            // 颜色预览框
            GestureDetector(
              onTap: () {
                _openColorPicker(
                  initialColor: _fillColor.color,
                  onColorSelected: (color) {
                    setState(() {
                      _fillColor = color.string;
                      _canvalsFillColorController.text = color.string;
                      _updateModel();
                    });
                  },
                  context: context,
                );
              },
              child: Container(
                width: 84.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: _fillColor.color,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: "#ffE6E6E6 ".color, width: 1.w),
                ),
              ),
            ),

            SizedBox(width: 10.w),

            // 颜色输入框
            Container(
              width: 84.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6 ".color, width: 1.w),
              ),
              child: TextField(
                controller: _canvalsFillColorController,
                textAlign: TextAlign.center,
                inputFormatters: [HexColorFormatter()],
                onChanged: (value) {
                  if (value.isNotEmpty && value.length == 7) {
                    setState(() {
                      _fillColor = value;
                      _updateModel();
                    });
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 15.w,
                  ),
                ),

                style: TextStyle(
                  fontSize: 14.w,
                  fontWeight: FontWeight.w600,
                  color: "#ff242424".color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillAlphaSection() {
    return SliderInputField(
      title: '填充透明度',
      value: _fillAlpha,
      minValue: 0.0,
      maxValue: 1.0,
      trackHeight: 8.w,
      thumbSize: 16.w,
      formatter: (value) => '${(value * 100).toInt()}%',
      parser: (text) =>
          double.tryParse(text.replaceAll('%', '')) ?? 0.0 / 100.0,
      onChanged: (value) {
        setState(() {
          _fillAlpha = value;
          // 滑动过程中只更新模型，不记录命令
          _updateModel(notify: false);
        });
      },
      onChangeEnd: (value) {
        // 滑动结束时记录命令
        _updateModel(notify: true);
      },
    );
  }
}
