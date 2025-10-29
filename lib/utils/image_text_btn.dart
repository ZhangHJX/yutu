import 'package:flutter/material.dart';

class ImageTextBtn extends StatelessWidget {
  final String imageUrl; // 图片地址
  final String text; // 文字内容
  final double spacing; // 图片与文字的间距
  final double imageSize; // 图片大小
  final TextStyle? textStyle; // 文字样式
  final VoidCallback? onTap; // 点击事件
  final Axis direction; // 布局方向，默认垂直（图片在上文字在下）

  const ImageTextBtn({
    super.key,
    required this.imageUrl,
    required this.text,
    this.spacing = 8,
    this.imageSize = 48,
    this.textStyle,
    this.onTap,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      Image.asset(
        imageUrl,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
      ),
      SizedBox(
        height: direction == Axis.vertical ? spacing : 0,
        width: direction == Axis.horizontal ? spacing : 0,
      ),
      Text(
        text,
        style:
            textStyle ?? const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    ];

    return GestureDetector(
      onTap: onTap,
      child: direction == Axis.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
    );
  }
}
