import 'package:flutter/material.dart';

/// 中间凸出的TabBar按钮组件
class CenterTabBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const CenterTabBarButton({
    super.key,
    required this.icon,
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
          child: Image.asset(
            'assets/images/tabBar/middle_bar_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// 自定义的TabBar，支持中间凸出按钮
class CustomTabBarWithCenter extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final List<TabBarItem> items;
  final Widget? centerButton;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double height;

  const CustomTabBarWithCenter({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
    this.centerButton,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.height = 83.0,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCol = selectedColor ?? const Color(0xFF6C64FF);
    final unselectedCol = unselectedColor ?? const Color(0xFF9E9E9E);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 底部TabBar
          Row(
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap?.call(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        isSelected ? item.selectePath : item.normalPath,
                        width: item.width,
                        height: item.height,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? selectedCol : unselectedCol,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          // 中间凸出按钮
          if (centerButton != null)
            Positioned(
              left: 0,
              right: 0,
              top: -26,
              child: Center(child: centerButton),
            ),
        ],
      ),
    );
  }
}

/// TabBar项目模型
class TabBarItem {
  final String normalPath;
  final String selectePath;
  final double width;
  final double height;
  final String label;

  const TabBarItem({
    required this.normalPath,
    required this.selectePath,
    required this.label,
    required this.width,
    required this.height,
  });
}
