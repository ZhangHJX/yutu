import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'widgets/search_bar_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  // final logic = Get.put(HomeLogic());

  @override
  Widget build(BuildContext context) {
    debugPrint("------${MediaQuery.of(context).padding.top}");
    debugPrint("------${MediaQuery.of(context).padding.bottom}");
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFE3EEF7)],
          ),
        ),
        child: Column(
          children: [
            // 状态栏占位
            SizedBox(height: MediaQuery.of(context).padding.top),

            // 搜索框区域
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 20.h, left: 16.w, right: 16.w),
              child: SearchBarWidget(
                hintText: '搜索一下吧~',
                onSearch: (searchText) {
                  _handleSearch(searchText);
                },
                onIconTap: () {
                  _handleIconTap();
                },
                onSearchButtonTap: () {
                  _handleSearchButtonTap();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 处理搜索事件
  void _handleSearch(String searchText) {
    if (searchText.isNotEmpty) {
      debugPrint('搜索内容: $searchText');
      // 这里可以添加实际的搜索逻辑
      // 例如：导航到搜索结果页面、调用搜索API等
    }
  }

  // 处理左侧图标点击事件
  void _handleIconTap() {
    debugPrint('左侧星星图标被点击');
    // 这里可以添加图标点击的逻辑
    // 例如：显示特殊功能、打开菜单等
  }

  // 处理搜索按钮点击事件
  void _handleSearchButtonTap() {
    debugPrint('搜索按钮被点击');
    // 这里可以添加搜索按钮点击的逻辑
    // 例如：显示搜索历史、打开高级搜索等
  }
}
