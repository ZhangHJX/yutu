import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'home_logic.dart';
import 'widgets/search_navigation_widget.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'widgets/home_page_item.dart';
import 'package:voicetemplate/core/index.dart';
import '../widgets/page_empty_state.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final logic = Get.put(HomeLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9ADEFD),
              Color(0xFFF7F7F7),
              Color(0xFFF7F7F7),
              Color(0xFFE3EEF7),
            ],
            stops: [0.0, 0.25, 0.25, 1.0],
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.search),
              child: SearchNavigationWidget(isEnabled: false),
            ),

            Expanded(
              child: SmartRefresher(
                key: logic.refresherKey,
                controller: logic.refreshController,
                enablePullUp: true,
                onRefresh: () async {
                  await logic.homeRefresh();
                },
                onLoading: () async {
                  await logic.onLoad();
                },
                child: CustomScrollView(
                  slivers: [
                    // 精彩推荐区域
                    SliverToBoxAdapter(child: _buildWonderfulRecommendations()),
                    // Tab 栏（使用 SliverPersistentHeader 实现固定在顶部效果）
                    SliverPersistentHeader(
                      pinned: true, // 设置为 true 实现固定在顶部效果
                      delegate: _TabBarDelegate(child: _buildTabBar()),
                    ),
                    // 瀑布流内容列表
                    SliverToBoxAdapter(
                      child: Obx(() {
                        if (logic.tagList.isEmpty) {
                          return const PageEmptyState(title: '未找到匹配的模板~');
                        }
                        final tagId =
                            logic.tagList[logic.selectedTabIndex.value].id;
                        final tabData = logic.tabDataMap[tagId];

                        if (tabData == null || tabData.dataList.isEmpty) {
                          return const PageEmptyState(title: '未找到匹配的模板~');
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                            left: 15.w,
                            right: 15.w,
                            top: 8.w,
                          ),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14.h,
                            crossAxisSpacing: 9.w,
                            shrinkWrap: true,
                            padding: EdgeInsets.only(bottom: 30.w),
                            primary: false,
                            itemCount: tabData.dataList.length,
                            itemBuilder: (context, index) {
                              final item = tabData.dataList[index];
                              return HomePageItem(
                                key: ValueKey(item.id),
                                model: item,
                                source: PageSource.home,
                                favoriteCallBack: () {
                                  if (!logic.global.isLogin) {
                                    Get.toNamed(AppRoutes.appLogin);
                                    return;
                                  }
                                  if (item.isFavorite == 1) {
                                    logic.favoriteEventDialog(item.id);
                                  } else {
                                    logic.clickFavorite(item.id, true);
                                  }
                                },
                              );
                            },
                          ),
                        );
                      }),
                    ),
                    // 底部间距
                    SliverToBoxAdapter(child: SizedBox(height: 30.w)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建精彩推荐区域
  Widget _buildWonderfulRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/home/hone_recomend_icon.png',
                width: 80.64.w,
                height: 31.68.w,
                fit: BoxFit.cover,
              ),
              Text(
                '为你精选',
                style: TextStyle(
                  fontSize: 12.w,
                  color: '#A4AEBD'.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.w),

        // 横向滚动卡片
        Obx(() {
          return Container(
            padding: EdgeInsets.only(left: 15.w, bottom: 9.w),
            height: 201.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: logic.recommendList.length,
              itemBuilder: (context, index) {
                final item = logic.recommendList[index];
                return Container(
                  width: 135.w,
                  margin: EdgeInsets.only(right: 9.w),
                  clipBehavior: Clip.antiAlias, // 或 Clip.hardEdge
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: '${item.originalImage}${item.thumbnail}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: "#F5F5F5".color,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: "#9082FF".color,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: "#F5F5F5".color,
                            child: Icon(
                              Icons.broken_image,
                              color: "#CCCCCC".color,
                              size: 24.w,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 30.w,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFE0E0), Color(0xFFFFF0E0)],
                            ),
                          ),
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12.w,
                              color: '#FFFFFF'.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // 构建 Tab 栏
  Widget _buildTabBar() {
    return SizedBox(
      height: 44.0,
      child: Stack(
        children: [
          // 可滚动的标签列表
          Align(
            alignment: Alignment.centerLeft,
            child: Obx(
              () => AutoScrollTabBar(
                screenList: logic.tagList,
                tabController: logic.tabController.value,
                onTabTap: (index) => logic.switchTab(index),
                rightMargin: 53.w,
                textColor: '#2A6181',
                textSelectColor: '#007BFE',
                itemBackColor: '#E9F2F7',
                itemSelectBackColor: '#DCEDFE',
              ),
            ),
          ),

          // 右侧固定图片
          Positioned(
            right: 0.w,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.search),
              child: Container(
                color: "#F7F7F7".color,
                child: Center(
                  child: Image.asset(
                    'assets/images/home/home_screen_more.png',
                    width: 53.w,
                    height: 26.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tab 栏的 SliverPersistentHeaderDelegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  double get minExtent => 44.0; // 最小高度

  @override
  double get maxExtent => 44.0; // 最大高度

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: maxExtent, child: child);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
