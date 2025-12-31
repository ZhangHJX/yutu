import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_bar_widget.dart';

class SearchNavigationWidget extends StatelessWidget {
  const SearchNavigationWidget({
    super.key,
    required this.isEnabled,
    this.children = const [],
    this.onSearch,
  });
  final List<Widget> children;
  final bool isEnabled;
  final Function(String)? onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: ScreenTools.statusBarHeight,
          color: Colors.transparent,
        ),
        SizedBox(height: 13.w),

        // 搜索框区域
        Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(left: isEnabled ? 5.w : 15.w, right: 15.w),
          child: Row(
            children: [
              if (isEnabled)
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
                child: SearchBarWidget(
                  isEnabled,
                  hintText: '搜索一下吧～',
                  onSearch: onSearch,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.w),

        ...children,
      ],
    );
  }
}
