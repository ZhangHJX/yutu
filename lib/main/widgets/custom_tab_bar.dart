import 'package:flutter/material.dart';
import 'tab_bar_item.dart';
import 'const.dart';

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
      color: Colors.white,
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
                      buildTabIcon(item, isSelected),
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
