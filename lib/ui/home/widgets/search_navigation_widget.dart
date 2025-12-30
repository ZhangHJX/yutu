import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_bar_widget.dart';

class SearchNavigationWidget extends StatelessWidget {
  const SearchNavigationWidget({
    super.key,
    required this.isEnabled,
    required this.onTap,
    this.children = const [],
  });
  final VoidCallback? onTap;
  final List<Widget> children;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: ScreenTools.statusBarHeight,
          color: Colors.transparent,
        ),
        SizedBox(height: 13.w),
        // 搜索框区域
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: SearchBarWidget(
              isEnabled,
              hintText: isEnabled ? '' : '搜索一下吧～',
            ),
          ),
        ),
        SizedBox(height: 8.w),

        ...children,
      ],
    );
  }
}
