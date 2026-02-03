import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../components/color_picker_dialog.dart';
import '../../components/slider_input_field.dart';
import '../../../../../core/utils/text_filed/border_width_formatter.dart';
import '../../input_number_formatter.dart';
import 'package:voicetemplate/core/index.dart';

/// 颜色效果组件
class ColorEffectWidget extends StatefulWidget {
  final dynamic element;
  final Function(bool notify)? onPropertyChanged;
  final Function(
    String,
    double,
    String,
    int,
    double,
    bool,
    String,
    double,
    double,
    double,
    double,
    bool,
  )
  onColorEffectChanged;

  const ColorEffectWidget({
    super.key,
    required this.element,
    this.onPropertyChanged,
    required this.onColorEffectChanged,
  });

  @override
  State<ColorEffectWidget> createState() => _ColorEffectWidgetState();
}

class _ColorEffectWidgetState extends State<ColorEffectWidget> {
  // 文字颜色
  String _textColor = '#000000';
  final TextEditingController _textColorController = TextEditingController(
    text: '#000000',
  );
  double _textAlpha = 1;

  // 边框颜色
  String _borderColor = '#FFA500';
  final TextEditingController _borderColorController = TextEditingController();
  final TextEditingController _borderWidthController = TextEditingController();
  int _borderWidth = 1;
  double _borderAlpha = 1;

  // 阴影
  String _shadowColor = '#A020F0';
  double _shadowX = 0.0;
  double _shadowY = 0.0;
  double _shadowBlur = 0.0;

  final TextEditingController _shadowColorController = TextEditingController();
  final TextEditingController _shadowXController = TextEditingController();
  final TextEditingController _shadowYController = TextEditingController();
  final TextEditingController _shadowBlurController = TextEditingController();
  bool _shadowEnabled = false;
  double _shawAlpha = 1;

  @override
  void initState() {
    super.initState();
    _initializeFromModel();
  }

  /// 从模型初始化UI状态
  void _initializeFromModel() {
    if (widget.element == null) return;

    final data = widget.element;

    // 初始化文字颜色
    _textColor = data.textColor;
    _textColorController.text = _textColor;
    _textAlpha = data.textAlpha;

    // 初始化描边（对应fillColor2）
    _borderColor = data.borderColor;
    _borderColorController.text = _borderColor;
    _borderWidth = data.borderWidth?.toInt();
    _borderWidthController.text = _borderWidth.toInt().toString();
    _borderAlpha = data.borderAlpha;

    _shadowX = data?.shawX ?? 0;
    _shadowY = data?.shawY ?? 0;
    _shadowBlur = data?.blurValue ?? 0;

    // 初始化阴影
    _shadowEnabled = data.isShawOpen ?? false;
    _shadowColor = data.shawColor ?? '#A020F0';
    _shadowColorController.text = _shadowColor;
    _shadowXController.text = _shadowX.toInt().toString();
    _shadowYController.text = _shadowY.toInt().toString();
    _shadowBlurController.text = _shadowBlur.toInt().toString();
    _shawAlpha = data.shawAlpha;
  }

  @override
  void dispose() {
    _textColorController.dispose();
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

  void _updateModel({bool notify = true}) {
    widget.onColorEffectChanged(
      _textColor,
      _textAlpha,
      _borderColor,
      _borderWidth,
      _borderAlpha,
      _shadowEnabled,
      _shadowColor,
      double.tryParse(_shadowXController.text) ?? 0,
      double.tryParse(_shadowYController.text) ?? 0,
      double.tryParse(_shadowBlurController.text) ?? 0,
      _shawAlpha,
      notify,
    );
    widget.onPropertyChanged?.call(notify);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 21.w),
          // 填充 描边
          _buildFillBorderSection(context),
          SizedBox(height: 2.w),
          //透明度
          _buildFillAndBorderAlaphSection(),
          SizedBox(height: 7.w),
          // 阴影
          _buildShadowSection(context),

          if (_shadowEnabled) SizedBox(height: 21.w),
          if (_shadowEnabled) _buildShawAlaphSection(),

          SizedBox(height: ScreenTools.bottomBarHeight + 15.w),
        ],
      ),
    );
  }

  Widget _buildFillBorderSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 字体
        Column(
          children: [
            GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus(); // 收起键盘
                _openColorPicker(
                  initialColor: _textColor.color,
                  onColorSelected: (color) {
                    setState(() {
                      _textColor = color.string;
                      _textColorController.text = color.string;
                      _updateModel();
                    });
                  },
                  context: context,
                );
              },
              child: Container(
                width: 50.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: _textColor.color,
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

        // 字体颜色
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
                controller: _textColorController,
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
                      _textColor = value;
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
                FocusManager.instance.primaryFocus?.unfocus(); // 收起键盘
                _openColorPicker(
                  initialColor: _borderColor.color,
                  onColorSelected: (color) {
                    setState(() {
                      _borderColor = color.string;
                      _borderColorController.text = color.string;
                      _updateModel();
                    });
                  },
                  context: context,
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
                      _borderWidth = newValue;
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
          value: _textAlpha,
          minValue: 0.0,
          maxValue: 1.0,
          trackHeight: 8.w,
          thumbSize: 16.w,
          formatter: (value) => '${(value * 100).toInt()}%',
          parser: (text) =>
              double.tryParse(text.replaceAll('%', '')) ?? 0.0 / 100.0,
          onChanged: (value) {
            setState(() {
              _textAlpha = value;
              // 滑动过程中只更新模型，不记录命令
              _updateModel(notify: false);
            });
          },
          onChangeEnd: (value) {
            // 滑动结束时记录命令
            _updateModel(notify: true);
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
              // 滑动过程中只更新模型，不记录命令
              _updateModel(notify: false);
            });
          },
          onChangeEnd: (value) {
            // 滑动结束时记录命令
            _updateModel(notify: true);
          },
        ),
      ],
    );
  }

  Widget _buildShadowSection(BuildContext context) {
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

        if (_shadowEnabled) SizedBox(height: 6.w),

        // 颜色预览、输入框、X、Y
        if (_shadowEnabled)
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
                    context: context,
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
                          inputFormatters: [InputNumberFormatter()],
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
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15.w,
                            ),
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
                          inputFormatters: [InputNumberFormatter()],
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
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15.w,
                            ),
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
                      padding: EdgeInsets.only(left: 12.w, top: 2.w),
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
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: TextField(
                          controller: _shadowBlurController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [InputNumberFormatter()],
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
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15.w,
                            ),
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
