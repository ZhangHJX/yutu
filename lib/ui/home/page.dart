import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'widgets/search_bar_widget.dart';
import 'home_logic.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final logic = Get.put(HomeLogic());

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFE3EEF7)],
          ),
        ),
        child: Container(),
      ),
    );
  }

  /*
  
  NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              // 状态栏占位
              SliverToBoxAdapter(child: SizedBox(height: statusBarHeight)),

              // 搜索框区域
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 20.h,
                    left: 16.w,
                    right: 16.w,
                    bottom: 20.h,
                  ),
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
              ),

              // 精彩推荐区域
              SliverToBoxAdapter(child: _buildWonderfulRecommendations()),

              // Tab 栏（使用 SliverPersistentHeader 实现悬停效果）
              SliverPersistentHeader(
                pinned: true, // 设置为 true 实现悬停效果
                delegate: _TabBarDelegate(
                  child: Obx(() => _buildTabBar(context)),
                ),
              ),
            ];
          },
          body: Builder(
            builder: (BuildContext context) {
              return CustomScrollView(
                slivers: [
                  // 内容列表
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildContentItem(index);
                        },
                        childCount: 20, // 示例数据，可以根据实际需求修改
                      ),
                    ),
                  ),

                  // 底部间距
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],
              );
            },
          ),
        ),
  
  
  */

  // 构建精彩推荐区域
  Widget _buildWonderfulRecommendations() {
    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '精彩推荐',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '为你精选',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 横向滚动卡片
          SizedBox(
            height: 200.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 280.w,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12.r),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFE0E0), Color(0xFFFFF0E0)],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 80.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '福利待遇商用',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建 Tab 栏
  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              logic.tabs.length,
              (index) => GestureDetector(
                onTap: () => logic.switchTab(index),
                child: Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: logic.selectedTabIndex.value == index
                        ? const Color(0xFF4A90E2)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    logic.tabs[index],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: logic.selectedTabIndex.value == index
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: logic.selectedTabIndex.value == index
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建内容项
  Widget _buildContentItem(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片区域
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                ),
              ),
              child: Center(
                child: Icon(Icons.image, size: 60.sp, color: Colors.grey[400]),
              ),
            ),
          ),

          // 文字信息
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可改字/自带头像/改字体',
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withAlpha(51),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '官方',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.favorite, size: 14.sp, color: Colors.grey[400]),
                    SizedBox(width: 4.w),
                    Text(
                      '9999',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// Tab 栏的 SliverPersistentHeaderDelegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  double get minExtent => 56.0; // 最小高度

  @override
  double get maxExtent => 56.0; // 最大高度

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
