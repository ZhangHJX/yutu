import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../utils/index.dart';
import './widgets/slider_input_field.dart';
import '../../model/index.dart';

class ShapePropertyDialog extends StatefulWidget {
  final CanvasElement? element;
  final VoidCallback? onDeleteShape;
  final Function(CanvasElement)? onPropertiesChanged;

  const ShapePropertyDialog({
    super.key,
    this.element,
    this.onDeleteShape,
    this.onPropertiesChanged,
  });

  @override
  State<ShapePropertyDialog> createState() => _ShapePropertyDialogState();
}

class _ShapePropertyDialogState extends State<ShapePropertyDialog> {
  // 填充颜色
  late String _fillColor;
  double _fillAlpha = 1.0;
  final TextEditingController _fillColorController = TextEditingController();

  // 边框颜色
  late String _borderColor;
  late int _borderWidth;
  final TextEditingController _borderColorController = TextEditingController();
  final TextEditingController _borderWidthController = TextEditingController();
  double _borderAlpha = 1.0;

  // 阴影颜色
  late String _shadowColor;
  late double _shadowOffsetX;
  late double _shadowOffsetY;
  late double _shadowBlur;
  late bool _shadowEnabled; // 阴影启用状态
  final TextEditingController _shadowColorController = TextEditingController();
  final TextEditingController _shadowXController = TextEditingController();
  final TextEditingController _shadowYController = TextEditingController();
  final TextEditingController _shadowBlurController = TextEditingController();
  double _shawAlpha = 1;

  @override
  void initState() {
    super.initState();
    _initializeFromModel();
  }

  /// 从模型数据初始化所有属性
  void _initializeFromModel() {
    final data = widget.element;

    // 初始化填充颜色
    _fillColor = data?.fillColor ?? '#D8D8D8';
    _fillColorController.text = data?.fillColor ?? '#D8D8D8';
    _fillAlpha = data?.fillAlpha ?? 1.0;

    // 初始化边框属性
    _borderColor = data?.borderColor ?? '#D8D8D8';
    _borderColorController.text = data?.borderColor ?? '#D8D8D8';
    _borderWidth = data?.borderWidth ?? 0;
    _borderWidthController.text = _borderWidth.toInt().toString();
    _borderAlpha = data?.borderAlpha ?? 1.0;

    // 初始化阴影属性
    _shadowColor = data?.shawColor ?? '#D8D8D8';
    _shadowColorController.text = data?.shawColor ?? '#D8D8D8';
    _shadowOffsetX = data?.shawX ?? 0.0;
    _shadowOffsetY = data?.shawY ?? 0.0;
    _shadowBlur = data?.blurValue ?? 0.0;
    _shadowEnabled = data?.isShawOpen ?? false; // 初始化阴影启用状态
    _shadowXController.text = _shadowOffsetX.toInt().toString();
    _shadowYController.text = _shadowOffsetY.toInt().toString();
    _shadowBlurController.text = _shadowBlur.toInt().toString();
    _shawAlpha = data?.shawAlpha ?? 1.0;
  }

  /// 更新模型数据
  void _updateModel() {
    final data = widget.element;
    if (data != null) {
      data.fillColor = _fillColorController.text;
      data.borderColor = _borderColorController.text;
      data.borderWidth = _borderWidth;
      data.shawColor = _shadowColorController.text;
      data.shawX = _shadowOffsetX;
      data.shawY = _shadowOffsetY;
      data.blurValue = _shadowBlur;
      data.isShawOpen = _shadowEnabled; // 更新阴影启用状态
      data.fillAlpha = _fillAlpha;
      data.borderAlpha = _borderAlpha;
      data.shawAlpha = _shawAlpha;

      if (data.type == ElementType.line) {
        data.height += _borderWidth * 2;
      }

      widget.onPropertiesChanged?.call(data);
    }
  }

  @override
  void dispose() {
    _fillColorController.dispose();
    _borderColorController.dispose();
    _borderWidthController.dispose();
    _shadowColorController.dispose();
    _shadowXController.dispose();
    _shadowYController.dispose();
    _shadowBlurController.dispose();
    super.dispose();
  }

  /// 打开颜色选择器
  void _openColorPicker({
    required Color initialColor,
    required ValueChanged<Color> onColorSelected,
  }) async {
    final selectedColor = await showColorPickerDialog(
      context,
      initialColor: initialColor,
    );

    if (selectedColor != null) {
      onColorSelected(selectedColor);
    }
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

          return Container(
            width: ScreenTools.screenWidth,
            // ⭐ 动态调整底部边距，避免被键盘遮挡
            margin: EdgeInsets.only(bottom: keyboardHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.w),
                topRight: Radius.circular(12.w),
              ),
            ),
            // ⭐ 添加 SingleChildScrollView 使内容可滚动
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                            '形状属性',
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
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 10.w,
                    top: 5.w,
                    bottom: 5.w,
                  ),
                  child: Column(
                    children: [
                      // 填充 描边
                      _buildFillBorderSection(),
                      SizedBox(height: 2.w),
                      //透明度
                      _buildFillAndBorderAlaphSection(),
                      SizedBox(height: 7.w),
                      // 阴影
                      _buildShadowSection(),

                      SizedBox(height: 21.w),
                      _buildShawAlaphSection(),
                    ],
                  ),
                ),

                // 删除按钮
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        widget.onDeleteShape?.call();
                        SmartDialog.dismiss();
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          left: 22.w,
                          right: 22.w,
                          top: 22.w,
                        ),
                        width: double.infinity,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(
                            color: "#FFFF3333".color,
                            width: 1.w,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '删除形状',
                            style: TextStyle(
                              fontSize: 16.w,
                              fontWeight: FontWeight.w500,
                              color: "#FFFF3333".color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 底部安全区域
                    SizedBox(height: ScreenTools.bottomBarHeight + 20),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFillBorderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 填充
        Column(
          children: [
            GestureDetector(
              onTap: () {
                _openColorPicker(
                  initialColor: _fillColor.color,
                  onColorSelected: (color) {
                    setState(() {
                      _fillColor = color.string;
                      _fillColorController.text = color.string;
                      _updateModel();
                    });
                  },
                );
              },
              child: Container(
                width: 50.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: _fillColor.color,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: "#ffE6E6E6 ".color, width: 1.w),
                ),
              ),
            ),

            SizedBox(height: 2.w),

            Text(
              '填充',
              style: TextStyle(
                fontSize: 14.w,
                color: "#3E3E3E".color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        SizedBox(width: 4.w),

        // 填充输入框
        Column(
          children: [
            Container(
              width: 70.w,
              height: 38.w,
              padding: EdgeInsets.only(left: 3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
              ),
              child: TextField(
                controller: _fillColorController,
                inputFormatters: [HexColorFormatter()],
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                ),
                style: TextStyle(
                  fontSize: 11.w,
                  fontWeight: FontWeight.w600,
                  color: "#242424".color,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && value.length == 7) {
                    setState(() {
                      _fillColor = value;
                      _updateModel();
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 22.w),
          ],
        ),

        SizedBox(width: 13.w),

        // 描边
        Column(
          children: [
            GestureDetector(
              onTap: () {
                _openColorPicker(
                  initialColor: _borderColor.color,
                  onColorSelected: (color) {
                    setState(() {
                      _borderColor = color.string;
                      _borderColorController.text = color.string;
                      _updateModel();
                    });
                  },
                );
              },
              child: Container(
                width: 50.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: _borderColor.color,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: "#ffE6E6E6 ".color, width: 1.w),
                ),
              ),
            ),

            SizedBox(height: 2.w),

            Text(
              '描边',
              style: TextStyle(
                fontSize: 14.w,
                color: "#ff3E3E3E".color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        SizedBox(width: 3.w),

        // 描边颜色输入框
        Column(
          children: [
            Container(
              width: 70.w,
              height: 38.w,
              padding: EdgeInsets.only(left: 3.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _borderColorController,
                textAlign: TextAlign.center,
                inputFormatters: [HexColorFormatter()],
                onChanged: (value) {
                  if (value.isNotEmpty && value.length == 7) {
                    setState(() {
                      _borderColor = value;
                      _updateModel();
                    });
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                ),
                style: TextStyle(
                  fontSize: 11.w,
                  fontWeight: FontWeight.w600,
                  color: "#ff242424".color,
                ),
              ),
            ),
            SizedBox(height: 22.w),
          ],
        ),

        SizedBox(width: 5.w),

        // 边框图标
        Column(
          children: [
            Image.asset(
              'assets/images/canvals/canvals_border_icon.png',
              width: 26.w,
              height: 26.w,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 2.w),
            Text(
              '',
              style: TextStyle(
                fontSize: 14.w,
                color: "#3E3E3E".color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        SizedBox(width: 6.w),

        // 边框大小输入框
        Column(
          children: [
            Container(
              width: 48.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#E6E6E6".color, width: 1.w),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _borderWidthController,
                inputFormatters: [BorderWidthFormatter(100)],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final newValue = int.tryParse(value);
                  if (newValue != null) {
                    setState(() {
                      _borderWidth = newValue.toInt();
                      _updateModel();
                    });
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                ),
                style: TextStyle(
                  fontSize: 11.w,
                  fontWeight: FontWeight.w600,
                  color: "#ff242424".color,
                ),
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              '',
              style: TextStyle(
                fontSize: 14.w,
                color: "#3E3E3E".color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillAndBorderAlaphSection() {
    return Column(
      children: [
        SliderInputField(
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
              _updateModel();
            });
          },
        ),

        SizedBox(height: 7.w),

        SliderInputField(
          title: '边框透明度',
          value: _borderAlpha,
          minValue: 0.0,
          maxValue: 1.0,
          trackHeight: 8.w,
          thumbSize: 16.w,
          formatter: (value) => '${(value * 100).toInt()}%',
          parser: (text) =>
              double.tryParse(text.replaceAll('%', '')) ?? 0.0 / 100.0,
          onChanged: (value) {
            setState(() {
              _borderAlpha = value;
              _updateModel();
            });
          },
        ),
      ],
    );
  }

  Widget _buildShadowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '阴影',
              style: TextStyle(
                fontSize: 14.w,
                color: "#ff3E3E3E".color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),

            GestureDetector(
              onTap: () {
                setState(() {
                  _shadowEnabled = !_shadowEnabled;
                  _updateModel();
                });
              },
              child: Row(
                children: [
                  // canvals_shaw_unon
                  Image.asset(
                    _shadowEnabled
                        ? 'assets/images/canvals/canvals_shaw_on.png'
                        : 'assets/images/canvals/canvals_shaw_unon.png',
                    width: 14.w,
                    height: 14.w,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _shadowEnabled ? '启用' : "未启用",
                    style: TextStyle(
                      fontSize: 14.w,
                      color: _shadowEnabled ? "#A77AFF".color : "#A4A4A4".color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 6.w),

        // 颜色预览、输入框、X、Y
        Row(
          children: [
            // 颜色预览框
            GestureDetector(
              onTap: () {
                _openColorPicker(
                  initialColor: _shadowColor.color,
                  onColorSelected: (color) {
                    setState(() {
                      _shadowColor = color.string;
                      _shadowColorController.text = color.string;
                      _updateModel();
                    });
                  },
                );
              },
              child: Container(
                width: 50.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: _shadowColor.color,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: "#ffE6E6E6 ".color, width: 1.w),
                ),
              ),
            ),

            SizedBox(width: 2.w),

            // 颜色输入框
            Container(
              width: 70.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _shadowColorController,
                textAlign: TextAlign.center,
                inputFormatters: [HexColorFormatter()],
                onChanged: (value) {
                  if (value.isNotEmpty && value.length == 7) {
                    setState(() {
                      _shadowColor = value;
                      _updateModel();
                    });
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                ),
                style: TextStyle(
                  fontSize: 11.w,
                  fontWeight: FontWeight.w600,
                  color: "#ff242424".color,
                ),
              ),
            ),

            SizedBox(width: 5.w),

            // X 偏移输入框
            Container(
              width: 67.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: Text(
                      'X',
                      style: TextStyle(
                        fontSize: 14.w,
                        fontWeight: FontWeight.w600,
                        color: "#ff242424".color,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 5.w),
                      child: TextField(
                        controller: _shadowXController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final x = double.tryParse(value);
                            if (x != null) {
                              _updateModel();
                            }
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                        ),
                        style: TextStyle(
                          fontSize: 12.w,
                          fontWeight: FontWeight.w600,
                          color: "#ff242424".color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 4.w),

            // Y 偏移输入框
            Container(
              width: 67.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: Text(
                      'Y',
                      style: TextStyle(
                        fontSize: 14.w,
                        fontWeight: FontWeight.w600,
                        color: "#ff242424".color,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 5.w),
                      child: TextField(
                        controller: _shadowYController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final y = double.tryParse(value);
                            if (y != null) {
                              _updateModel();
                            }
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                        ),
                        style: TextStyle(
                          fontSize: 12.w,
                          fontWeight: FontWeight.w600,
                          color: "#ff242424".color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 4.w),

            // 模糊输入框
            Container(
              width: 72.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12.w),
                    child: Text(
                      '模糊',
                      style: TextStyle(
                        fontSize: 12.w,
                        fontWeight: FontWeight.w600,
                        color: "#ff242424".color,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: TextField(
                        controller: _shadowBlurController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final blur = double.tryParse(value);
                            if (blur != null) {
                              _updateModel();
                            }
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15.w),
                        ),
                        style: TextStyle(
                          fontSize: 12.w,
                          fontWeight: FontWeight.w500,
                          color: "#ff242424".color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShawAlaphSection() {
    return SliderInputField(
      title: '阴影透明度',
      value: _shawAlpha,
      minValue: 0.0,
      maxValue: 1.0,
      trackHeight: 8.w,
      thumbSize: 16.w,
      formatter: (value) => '${(value * 100).toInt()}%',
      parser: (text) =>
          double.tryParse(text.replaceAll('%', '')) ?? 0.0 / 100.0,
      onChanged: (value) {
        setState(() {
          _shawAlpha = value;
          _updateModel();
        });
      },
    );
  }
}
