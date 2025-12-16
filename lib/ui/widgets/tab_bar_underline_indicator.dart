import 'package:flutter/material.dart';

class TabBarUnderlineIndicator extends Decoration {
  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;

  /// 指示器离 Tab 底部的距离（想贴底用 0）
  final double bottomOffset;

  const TabBarUnderlineIndicator({
    required this.width,
    required this.height,
    required this.color,
    this.borderRadius = BorderRadius.zero,
    this.bottomOffset = 0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedUnderlinePainter(
      width: width,
      height: height,
      color: color,
      borderRadius: borderRadius,
      bottomOffset: bottomOffset,
    );
  }
}

class _FixedUnderlinePainter extends BoxPainter {
  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;
  final double bottomOffset;

  _FixedUnderlinePainter({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
    required this.bottomOffset,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) {
      return;
    }

    final rect = offset & size;

    // 防止固定宽度比 Tab 还宽导致溢出
    final safeWidth = width <= rect.width ? width : rect.width;

    // ✅ 居中：以 rect.center.dx 为中心点
    final left = rect.center.dx - safeWidth / 2;
    final top = rect.bottom - height - bottomOffset;

    final indicatorRect = Rect.fromLTWH(left, top, safeWidth, height);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(borderRadius.toRRect(indicatorRect), paint);
  }
}
