import 'package:flutter/material.dart';

/// 基于系统Slider的自定义进度条
/// 使用Flutter的Slider组件配合自定义TrackShape和ThumbShape实现
class SliderBasedProgressBar extends StatelessWidget {
  /// 进度值，范围 0.0 到 1.0
  final double value;

  /// 进度改变回调
  final ValueChanged<double>? onChanged;

  /// 进度条高度
  final double trackHeight;

  /// 圆形手柄直径
  final double thumbSize;

  /// 最大值
  final double maxValue;

  /// 最小值
  final double minValue;

  const SliderBasedProgressBar({
    super.key,
    required this.value,
    this.onChanged,
    this.trackHeight = 8.0,
    this.thumbSize = 20.0,
    this.maxValue = 1.0,
    this.minValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 渐变颜色
    final gradientColors = [
      const Color(0xFFC86CFF), // 紫色
      const Color(0xFF5B98FF), // 蓝色
    ];

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        // 轨道高度
        trackHeight: trackHeight,
        // 自定义轨道形状（支持渐变和未填充部分）
        trackShape: _GradientSliderTrackShape(
          thumbSize: thumbSize,
          trackHeight: trackHeight,
          gradientColors: gradientColors,
        ),
        // 自定义手柄形状
        thumbShape: _CustomThumbShape(
          thumbSize: thumbSize,
          borderWidth: 1.0,
          gradientColors: gradientColors,
        ),
        // 禁用焦点环
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
        // 禁用激活颜色（使用自定义渐变）
        activeTrackColor: Colors.transparent,
        // 未激活轨道颜色
        inactiveTrackColor: const Color(0xFFE5E5E5),
        // 禁用值指示器
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(
        value: value,
        min: minValue,
        max: maxValue,
        onChanged: onChanged,
      ),
    );
  }
}

/// 自定义轨道形状 - 支持渐变填充和未填充部分
class _GradientSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  final double trackHeight;
  final double thumbSize;
  final List<Color> gradientColors;

  _GradientSliderTrackShape({
    required this.thumbSize,
    required this.trackHeight,
    required this.gradientColors,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Radius trackRadius = Radius.circular(trackHeight / 2);

    // 绘制渐变填充部分（左侧）
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left - thumbSize / 2,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    if (activeRect.width > 0) {
      final Paint gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(activeRect);

      context.canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, trackRadius),
        gradientPaint,
      );
    }

    // 绘制未填充部分（右侧）
    final Rect inactiveRect = Rect.fromLTRB(
      thumbCenter.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    if (inactiveRect.width > 0) {
      final Paint inactivePaint = Paint()
        ..color = sliderTheme.inactiveTrackColor ?? const Color(0xFFE5E5E5);

      context.canvas.drawRRect(
        RRect.fromRectAndRadius(inactiveRect, trackRadius),
        inactivePaint,
      );
    }
  }
}

/// 自定义手柄形状 - 白色圆形带边框
class _CustomThumbShape extends SliderComponentShape {
  final double thumbSize;
  final double borderWidth;
  final List<Color> gradientColors;

  _CustomThumbShape({
    required this.thumbSize,
    required this.borderWidth,
    required this.gradientColors,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbSize, thumbSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double>? activationAnimation,
    Animation<double>? enableAnimation,
    bool isDiscrete = false,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    SliderThemeData? sliderTheme,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final double radius = thumbSize / 2;

    // 根据当前value计算边框颜色
    final currentValue = value ?? 0.0;
    final thumbBorderColor = currentValue > 0
        ? Color.lerp(gradientColors[0], gradientColors[1], currentValue)!
        : gradientColors[0];

    // 绘制边框
    final Paint borderPaint = Paint()
      ..color = thumbBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, radius - borderWidth / 2, borderPaint);

    // 绘制白色填充
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - borderWidth, fillPaint);

    // 绘制阴影
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(
      Offset(center.dx, center.dy + 2),
      radius - borderWidth,
      shadowPaint,
    );
  }
}
