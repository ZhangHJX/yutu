import 'package:flutter/material.dart';

/// 渐变圆角进度条
class GradientProgressBar extends StatelessWidget {
  /// 0 ~ 1
  final double value;

  /// 高度
  final double height;

  /// 背景颜色
  final Color backgroundColor;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor = const Color(0xFFE4E5EA),
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final progressWidth = fullWidth * v;

        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            color: backgroundColor,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: progressWidth,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8556FF), // 右侧蓝
                      Color(0xFF3691FF), // 左侧紫
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
