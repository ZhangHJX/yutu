import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../widgets/page_navigation_bar.dart';
import 'search_bar_widget.dart';

class SearchNavigationWidget extends StatelessWidget {
  const SearchNavigationWidget({
    super.key,
    required this.onTap,
    this.children = const [],
  });
  final VoidCallback? onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PageNavigationBar(
      child: Column(
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
              child: SearchBarWidget(false),
            ),
          ),
          SizedBox(height: 8.w),

          ...children,
        ],
      ),
    );
  }
}
