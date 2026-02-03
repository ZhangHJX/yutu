import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicetemplate/pages/canvas/widgets/input_number_formatter.dart';
import 'slider_based_progress_bar.dart';

/// 带标题和输入框的滑块组件
/// 布局：
/// - 上面：左边是标题，右边是输入框
/// - 下面：SliderBasedProgressBar
class SliderInputField extends StatefulWidget {
  /// 标题文本
  final String title;

  /// 当前值
  final double value;

  /// 值改变回调（滑动过程中持续触发）
  final ValueChanged<double>? onChanged;

  /// 滑动结束回调（滑动结束时触发一次，用于记录历史）
  final ValueChanged<double>? onChangeEnd;

  /// 最小值
  final double minValue;

  /// 最大值
  final double maxValue;

  /// 输入框宽度
  final double? inputWidth;

  /// 输入框高度
  final double? inputHeight;

  /// 格式化显示文本的函数（例如：显示百分比）
  /// 参数：value（当前值），返回格式化后的字符串
  final String Function(double)? formatter;

  /// 从输入框文本解析值的函数
  /// 参数：text（输入框文本），返回解析后的值
  final double Function(String)? parser;

  /// 是否允许通过输入框编辑
  final bool editable;

  /// 滑块轨道高度
  final double? trackHeight;

  /// 滑块手柄大小
  final double? thumbSize;

  /// 标题样式
  final TextStyle? titleStyle;

  /// 输入框文本样式
  final TextStyle? inputTextStyle;

  /// 输入框装饰
  final BoxDecoration? inputDecoration;

  /// 标题行和滑块之间的间距
  final double? verticalSpacing;

  const SliderInputField({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.inputWidth,
    this.inputHeight,
    this.formatter,
    this.parser,
    this.editable = true,
    this.trackHeight,
    this.thumbSize,
    this.titleStyle,
    this.inputTextStyle,
    this.inputDecoration,
    this.verticalSpacing,
  });

  @override
  State<SliderInputField> createState() => _SliderInputFieldState();
}

class _SliderInputFieldState extends State<SliderInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = TextEditingController();
    _focusNode = FocusNode();
    initInputValue(_currentValue);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SliderInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      initInputValue(_currentValue);
    }
  }

  void initInputValue(double value) {
    _controller.text = '${(value * 100).toInt()}';
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _handleInputSubmit();
    }
  }

  void _handleInputSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      initInputValue(0);
      return;
    }
    double? newValue = (double.tryParse(text) ?? 0.0) / 100.0;
    widget.onChanged?.call(newValue);
  }

  void _onchangeTextFiled(double value) {
    setState(() {
      _currentValue = value;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    // 默认样式
    final defaultTitleStyle = TextStyle(
      fontSize: 14.w,
      color: "#3E3E3E".color.withValues(alpha: 0.6),
      fontWeight: FontWeight.w400,
    );

    final defaultInputTextStyle = TextStyle(
      fontSize: 14.w,
      color: "#242424".color,
      fontWeight: FontWeight.w600,
    );

    final defaultInputDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.w),
      border: Border.all(color: "#E6E6E6".color, width: 1.w),
    );

    final inputWidth = widget.inputWidth ?? 66.w;
    final inputHeight = widget.inputHeight ?? 28.w;
    final verticalSpacing = widget.verticalSpacing ?? 8.w;
    final trackHeight = widget.trackHeight ?? 14.w;
    final thumbSize = widget.thumbSize ?? 18.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和输入框行
        Row(
          children: [
            // 标题
            Text(widget.title, style: widget.titleStyle ?? defaultTitleStyle),

            Expanded(child: Container()),

            // 输入框
            Container(
              width: inputWidth,
              height: inputHeight,
              decoration: defaultInputDecoration,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                      InputNumberFormatter(),
                    ],
                    style: defaultInputTextStyle,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                        right: 12.w,
                      ).copyWith(right: 18.w),
                    ),

                    onSubmitted: (_) {
                      _handleInputSubmit();
                    },
                    onEditingComplete: () {
                      _handleInputSubmit();
                    },
                    onChanged: (value) {
                      double? changeValue =
                          (double.tryParse(value) ?? 0.0) / 100;
                      _onchangeTextFiled(changeValue);
                    },
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      right: 6.w,
                      left: 2.w,
                    ), // 和输入框右侧内边距匹配
                    child: Text("%", style: defaultInputTextStyle),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 垂直间距
        SizedBox(height: verticalSpacing),

        // 滑块：拖动时同步更新 TextField
        SliderBasedProgressBar(
          value: _currentValue,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
          trackHeight: trackHeight,
          thumbSize: thumbSize,
          onChanged: (value) {
            _onSliderChangeValue(value); // 滑块拖动 → 同步更新 TextField
            widget.onChanged?.call(value);
          },
          onChangeEnd: (value) {
            widget.onChangeEnd?.call(value);
          },
        ),
      ],
    );
  }

  void _onSliderChangeValue(double value) {
    setState(() {
      _currentValue = value;
    });
    _controller.text = '${(value * 100).toInt()}';
  }
}
