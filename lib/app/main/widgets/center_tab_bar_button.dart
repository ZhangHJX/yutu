import 'package:flutter/material.dart';
import 'const.dart';
import 'tab_bar_item.dart';

/// 中间凸出的TabBar按钮组件
class CenterTabBarButton extends StatelessWidget {
  final TabBarItem item;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const CenterTabBarButton({
    super.key,
    required this.item,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor,
    this.size = 70.0,
    this.iconSize = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size / 2), // size / 2 = 完全圆形
        ),
        child: Center(
          child: SizedBox(
            width: size * 0.7,
            height: size * 0.7,
            child: buildTabIcon(item, true),
          ),
        ),
      ),
    );
  }
}
