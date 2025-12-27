import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 独立的响应式 Tab 项组件，只有选中的 Tab 会重建
class TabItemWidget extends StatelessWidget {
  final VoidCallback tapCallBack;
  final String name;
  final bool isSelected;
  const TabItemWidget({
    super.key,
    required this.name,
    required this.isSelected,
    required this.tapCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tapCallBack,
      child: Container(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.w),
        decoration: BoxDecoration(
          color: isSelected ? "#DCEDFE".color : '#E9F2F7'.color,
          borderRadius: BorderRadius.circular(24.w),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14.w,
            color: isSelected ? "#007BFE".color : "#2A6181".color,
          ),
        ),
      ),
    );
  }
}
