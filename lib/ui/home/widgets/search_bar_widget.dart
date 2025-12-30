import 'package:common/common.dart';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final TextEditingController? controller;
  final bool isEnabled;

  const SearchBarWidget(
    this.isEnabled, {
    super.key,
    this.hintText,
    this.onSearch,
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
      height: 36.w,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isEnabled
            ? '#EBEBEB'.color.withValues(alpha: 0.8)
            : '#FFFFFF'.color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: '#FFFFFF'.color, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 6.w),
          // 左侧图标
          Image.asset(
            'assets/images/home/serach_left_icon.png',
            width: 28.w,
            height: 28.w,
            fit: BoxFit.cover,
          ),

          SizedBox(width: 7.w),
          // 搜索图标
          Image.asset(
            'assets/images/home/serach_middle_icon.png',
            width: 16.w,
            height: 14.5.w,
            fit: BoxFit.cover,
          ),

          // 搜索输入框
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              child: TextField(
                controller: _controller,
                enabled: widget.isEnabled,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: '#6E7A91'.color, fontSize: 12.w),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11.w),
                ),
                style: TextStyle(fontSize: 12.w, color: Colors.black),
              ),
            ),
          ),

          // 分隔线
          Container(width: 1.w, height: 19.w, color: '#DCEBFD'.color),

          // 搜索按钮
          GestureDetector(
            onTap: () {
              widget.onSearch?.call(_controller.text);
            },
            child: Padding(
              padding: EdgeInsets.only(left: 9.w, right: 13.w),
              child: Text(
                '搜索',
                style: TextStyle(color: '#B1B6C2'.color, fontSize: 14.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
