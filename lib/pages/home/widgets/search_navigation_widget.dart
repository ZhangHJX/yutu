import 'package:common/common.dart';
import 'package:flutter/material.dart';

class SearchNavigationWidget extends StatefulWidget {
  const SearchNavigationWidget({
    super.key,
    this.onSearch,
    this.onClear,
    this.controller,
    required this.onChanged,
  });

  final Function(String)? onSearch;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final Function(String) onChanged;

  @override
  State<SearchNavigationWidget> createState() => _SearchNavigationWidgetState();
}

class _SearchNavigationWidgetState extends State<SearchNavigationWidget> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  bool _isSearching = false; // 是否处于搜索状态

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
    _focusNode.dispose();
    super.dispose();
  }

  // 处理取消按钮点击
  void _handleCancel() {
    _controller.clear();
    _focusNode.unfocus(); // 取消焦点
    setState(() {
      _isSearching = false;
    });
    widget.onClear?.call(); // 调用清空回调
  }

  // 处理搜索按钮点击
  void _handleSearch() {
    if (_controller.text.isNotEmpty) {
      widget.onSearch?.call(_controller.text);
      // 搜索后取消焦点
      setState(() {
        _isSearching = true;
      });
    } else {
      showToast('请输入搜索内容');
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      margin: EdgeInsets.fromLTRB(0, 13.w, 0, 10.w),
      height: 36.w,
      child: Row(
        children: [
          IconButton(
            icon: Image.asset(
              'assets/images/global/ic_black_back.png',
              width: 26.w,
              height: 26.w,
            ),
            onPressed: () {
              Get.back();
            },
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: '#EBEBEB'.color.withValues(alpha: 0.8),
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

                  // 搜索图标
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 7.w, right: 10.w),
                      child: TextField(
                        maxLines: 1,
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: '搜索一下吧～',
                          hintStyle: TextStyle(
                            color: '#6E7A91'.color,
                            fontSize: 12.w,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8.w),
                        ),
                        style: TextStyle(fontSize: 12.w, color: Colors.black),
                        onSubmitted: (value) => _handleSearch(),
                        onChanged: (value) {
                          widget.onChanged.call(value);
                          if (_isSearching) {
                            setState(() {
                              _isSearching = !_isSearching;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 搜索按钮
          GestureDetector(
            onTap: () {
              _isSearching ? _handleCancel() : _handleSearch();
            },
            child: Padding(
              padding: EdgeInsets.only(left: 9.w, right: 13.w),
              child: Text(
                _isSearching ? '取消' : '搜索',
                style: TextStyle(color: '#B1B6C2'.color, fontSize: 14.w),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
