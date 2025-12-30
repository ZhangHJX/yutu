import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 独立的响应式 Tab 项组件，只有选中的 Tab 会重建
class TabItemWidget extends StatelessWidget {
  final VoidCallback tapCallBack;
  final String name;
  final bool isSelected;

  final Color selectColor;
  final Color unSelectColor;

  final Color selectTextColor;
  final Color unSelectTextColor;

  const TabItemWidget({
    super.key,
    required this.name,
    required this.isSelected,
    required this.tapCallBack,
    this.selectColor = const Color(0xFFDCEDFE),
    this.unSelectColor = const Color(0xFFE9F2F7),
    this.selectTextColor = const Color(0xFF007BFE),
    this.unSelectTextColor = const Color(0xFF2A6181),
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
          color: isSelected ? selectColor : unSelectColor,
          borderRadius: BorderRadius.circular(24.w),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14.w,
            color: isSelected ? selectTextColor : unSelectTextColor,
          ),
        ),
      ),
    );
  }
}
