import 'package:common/common.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final Function()? onIconTap;
  final Function()? onSearchButtonTap;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hintText,
    this.onSearch,
    this.onIconTap,
    this.onSearchButtonTap,
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧图标
          GestureDetector(
            onTap: widget.onIconTap,
            child: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Stack(
                  children: [
                    // 主星星图标
                    Center(
                      child: Icon(Icons.star, color: Colors.white, size: 16.sp),
                    ),
                    // 右上角小星星
                    Positioned(
                      top: 2.h,
                      right: 2.w,
                      child: Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 搜索图标
          Icon(Icons.search, color: Colors.grey[400], size: 20.sp),

          // 搜索输入框
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '搜索一下吧~',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(fontSize: 16.sp, color: Colors.black87),
                onSubmitted: (value) {
                  widget.onSearch?.call(value);
                },
                onChanged: (value) {
                  // 可以在这里添加实时搜索逻辑
                },
              ),
            ),
          ),

          // 分隔线
          Container(width: 1.w, height: 20.h, color: Colors.grey[300]),

          // 搜索按钮
          GestureDetector(
            onTap: () {
              widget.onSearchButtonTap?.call();
              widget.onSearch?.call(_controller.text);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                '搜索',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
