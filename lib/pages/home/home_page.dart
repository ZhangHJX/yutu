import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'home_logic.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'widgets/home_page_item.dart';
import 'package:voicetemplate/core/index.dart';
import '../widgets/page_empty_state.dart';
import './widgets/search_bar_widget.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final logic = Get.put(HomeLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Image.asset(
              'assets/images/global/top_navigation_bg.png',
              fit: BoxFit.cover,
              height: 240.w,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 240.w,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFE3EEF7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 7.w),
                // 搜索框区域
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.search),
                  child: Container(
                    color: Colors.transparent,
                    padding: EdgeInsets.only(left: 15.w, right: 15.w),
                    child: SearchBarWidget(false, hintText: '搜索一下吧～'),
                  ),
                ),

                SizedBox(height: 8.w),

                // 顶部 Tab，初始隐藏，当中间 Tab 滑到搜索框边缘时显示
                Obx(
                  () => logic.showTopTab.value
                      ? _buildTabBar()
                      : const SizedBox.shrink(),
                ),

                Expanded(
                  child: SmartRefresher(
                    key: logic.refresherKey,
                    controller: logic.refreshController,
                    enablePullUp: true,
                    enablePullDown: true,
                    onRefresh: () async {
                      await logic.homeRefresh();
                    },
                    onLoading: () async {
                      debugPrint('获取代理场景列表失败: onLoading');

                      await logic.onLoad();
                    },
                    child: CustomScrollView(
                      controller: logic.scrollController,
                      slivers: [
                        // 精彩推荐区域
                        SliverToBoxAdapter(
                          child: _buildWonderfulRecommendations(),
                        ),

                        /// 修改中间的tab栏 - 当顶部 Tab 显示时，隐藏中间 Tab
                        Obx(
                          () => logic.showTopTab.value
                              ? const SliverToBoxAdapter(
                                  child: SizedBox.shrink(),
                                )
                              : SliverToBoxAdapter(child: _buildTabBar()),
                        ),

                        // 瀑布流内容列表
                        Obx(() {
                          final list = logic.tabList;
                          if (list.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: PageEmptyState(title: '未找到匹配的模板~'),
                            );
                          }
                          return SliverPadding(
                            padding: EdgeInsets.only(
                              left: 15.w,
                              right: 15.w,
                              top: 8.w,
                              bottom: 30.w,
                            ),
                            sliver: SliverMasonryGrid(
                              gridDelegate:
                                  SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                  ),
                              mainAxisSpacing: 14.w,
                              crossAxisSpacing: 9.w,
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = logic.tabList[index];
                                  return HomePageItem(
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
                                childCount: list.length,
                                // 关键：重排后，通过 key 找到它现在的新 index
                                findChildIndexCallback: (Key key) {
                                  final id = (key as ValueKey).value;
                                  return list.indexWhere((e) => e.id == id);
                                },
                              ),
                            ),
                          );
                        }),
                        // 底部间距
                        // SliverToBoxAdapter(child: SizedBox(height: 30.w)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          padding: EdgeInsets.only(left: 22.w, right: 11.w, bottom: 10.32.w),
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

        // 横向滚动卡片
        Obx(() {
          return Container(
            padding: EdgeInsets.only(left: 20.w, bottom: 9.w),
            height: 201.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: logic.recommendList.length,
              itemBuilder: (context, index) {
                final item = logic.recommendList[index];
                return GestureDetector(
                  onTap: () => Get.toNamed(
                    AppRoutes.middle,
                    arguments: {'id': item.id, "type": PageSource.home},
                  ),
                  child: Container(
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
                              limitTitleByLength(item.title),
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
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  String limitTitleByLength(String s, {int max = 6}) {
    if (s.length <= max) return s;
    // 超过 6：取前 5 + …
    return '${s.substring(0, max - 1)}…';
  }

  // 构建 Tab 栏
  Widget _buildTabBar() {
    return Container(
      height: 44.0,
      // color: Color.from(alpha: 1.0, red: 0.977, green: 0.984, blue: 0.992),
      color: Colors.transparent,
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
            child: CButton(
              text: '更多',
              width: 53,
              textStyle: TextStyle(
                color: '#A4AEBD'.color,
                fontWeight: FontWeight.w500,
              ),
              onPressed: () => Get.toNamed(AppRoutes.search),
            ),
          ),
        ],
      ),
    );
  }
}
