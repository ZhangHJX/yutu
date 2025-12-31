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
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    // 监听文本变化
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
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
              padding: EdgeInsets.only(left: 7.w),
              child: TextField(
                maxLines: 1,
                controller: _controller,
                enabled: widget.isEnabled,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  // filled: true,
                  // fillColor: Colors.red,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: '#6E7A91'.color, fontSize: 12.w),
                  border: InputBorder.none,
                  isDense: true,
                  // contentPadding: EdgeInsets.symmetric(vertical: 5.w),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.w),
                  suffixIcon: _hasText
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 15.w,
                          onPressed: () {
                            _controller.clear(); // 清空
                            _focusNode.requestFocus(); // 清空后保持光标
                          },
                        )
                      : null,
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
