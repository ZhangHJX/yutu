import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../widgets/slider_based_progress_bar.dart';

/// 行距对齐组件
class SpacingAlignmentWidget extends StatefulWidget {
  final dynamic element;
  final Function(bool notify)? onPropertyChanged;
  final Function(double, double, TextAlign, bool) onSpacingAlignmentChanged;

  const SpacingAlignmentWidget({
    super.key,
    required this.element,
    this.onPropertyChanged,
    required this.onSpacingAlignmentChanged,
  });

  @override
  State<SpacingAlignmentWidget> createState() => _SpacingAlignmentWidgetState();
}

class _SpacingAlignmentWidgetState extends State<SpacingAlignmentWidget> {
  // 行距和字距
  double _lineHeight = 1.0;
  double _letterSpacing = 0;

  // 对齐
  TextAlign _textAlign = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _initializeFromModel();
  }

  /// 从模型初始化UI状态
  void _initializeFromModel() {
    if (widget.element == null) return;

    final data = widget.element;

    // 初始化行距和字距
    _lineHeight = data.lineHeight ?? 1.0;
    _letterSpacing = data.fontSpace ?? 0;

    // 初始化对齐方式
    _textAlign = data.align ?? TextAlign.left;
  }

  void _updateModel({bool notify = true}) {
    widget.onSpacingAlignmentChanged(
      _lineHeight,
      _letterSpacing,
      _textAlign,
      notify,
    );
    widget.onPropertyChanged?.call(notify);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.w),
        // 行距和字距
        _buildSpacingSection(),
        SizedBox(height: 13.w),
        // 对齐
        _buildAlignmentSection(),

        SizedBox(height: ScreenTools.bottomBarHeight + 40.w),
      ],
    );
  }

  Widget _buildSpacingSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 27.w),
      child: Column(
        children: [
          // 行距
          Row(
            children: [
              Text(
                '行距',
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff3E3E3E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),

              Expanded(child: Container()),

              Text(
                _lineHeight.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff007BFE".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: 7.w),

          _buildGradientSlider(
            _lineHeight,
            (value) {
              if (value <= 0.0001) return;
              setState(() {
                _lineHeight = value;
                _updateModel(notify: false);
              });
            },
            (value) {
              if (value <= 0.0001) return;
              _updateModel(notify: true);
            },
            min: 0.0,
            max: 3.0,
          ),

          SizedBox(height: 13.w),

          // 字距
          Row(
            children: [
              Text(
                '字距',
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff3E3E3E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(child: Container()),
              Text(
                _letterSpacing.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff007BFE".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          SizedBox(height: 7.w),

          _buildGradientSlider(
            _letterSpacing,
            (value) {
              setState(() {
                _letterSpacing = value;
                _updateModel(notify: false);
              });
            },
            (value) {
              if (value <= 0.0001) return;
              _updateModel(notify: true);
            },
            min: 0.0,
            max: 5.0,
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '对齐',
            style: TextStyle(
              fontSize: 16.w,
              color: "#ff3E3E3E".color,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 11.w),

          Container(
            width: 171.w,
            height: 59.w,
            padding: EdgeInsets.only(left: 9.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAlignmentButton(
                  TextAlign.left,
                  'assets/images/canvals/canvals_align_left.png',
                  '左对齐',
                ),
                _buildAlignmentButton(
                  TextAlign.center,
                  'assets/images/canvals/canvals_align_middle.png',
                  '居中对齐',
                ),
                _buildAlignmentButton(
                  TextAlign.right,
                  'assets/images/canvals/canvals_align_right.png',
                  '右对齐',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentButton(
    TextAlign align,
    String imagePath,
    String label,
  ) {
    final isSelected = _textAlign == align;
    return GestureDetector(
      onTap: () {
        setState(() {
          _textAlign = align;
          _updateModel();
        });
      },
      child: Column(
        children: [
          Image.asset(imagePath, width: 34.w, height: 34.w, fit: BoxFit.cover),

          Text(
            label,
            style: TextStyle(
              fontSize: 12.w,
              color: isSelected
                  ? "#ff9E9E9E".color
                  : "#ff9E9E9E".color.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // 创建渐变色滑块
  Widget _buildGradientSlider(
    double value,
    Function(double) onChanged,
    Function(double) onChangeEnd, {
    double min = 0.0,
    double max = 1.0,
  }) {
    return SliderBasedProgressBar(
      value: value,
      minValue: min,
      maxValue: max,
      trackHeight: 14.w,
      thumbSize: 18.w,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
    );
  }
}
