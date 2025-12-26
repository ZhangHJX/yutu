import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'design_tab_page.dart';
import 'widgets/design_bottom_bar.dart';
import '../widgets/page_navigation_bar.dart';

class AppDesignPage extends HookWidget {
  AppDesignPage({super.key});

  final logic = Get.put(AppDesiginLogic());

  @override
  Widget build(BuildContext context) {
    final tabController = useSyncedTabController(
      length: logic.screenList.length,
      currentIndex: logic.selectedTabIndex,
      onIndexChanged: (index) {
        logic.switchTab(index);
      },
    );

    return Scaffold(
      backgroundColor: '#F5F5F5'.color,
      body: Obx(() {
        // 如果screenList为空，显示加载状态
        if (logic.screenList.isEmpty) {
          return Column(
            children: [
              _buildNavigationBar(),
              Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        return Column(
          children: [
            /// 顶部部分
            _buildNavigationBar(),

            /// 中间内容区域 - 使用TabBarView显示tab内容
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: List.generate(logic.screenList.length, (index) {
                  return CKeepAlive(child: DesignTabPage());
                }),
              ),
            ),

            /// 底部操作栏（全选 / 取消 / 删除）
            Obx(
              () => Column(
                children: [
                  if (logic.isBatchMode.value) DesignBottomBar(),
                  if (ScreenTools.bottomBarHeight > 0 &&
                      logic.isBatchMode.value)
                    Container(
                      color: Colors.white,
                      height: ScreenTools.bottomBarHeight,
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNavigationBar() {
    return PageNavigationBar(
      child: Column(
        children: [
          Container(
            height: ScreenTools.statusBarHeight,
            color: Colors.transparent,
          ),

          SizedBox(
            height: 44.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: EdgeInsets.only(right: 5.w),
                  icon: Image.asset(
                    'assets/images/global/ic_black_back.png',
                    width: 26.w,
                    height: 26.w,
                  ),
                  onPressed: () {
                    EventBusManager.share.emit(AppEventType.mineRefresh);
                    Get.back();
                  },
                ),
                Text(
                  "我的设计",
                  style: TextStyle(
                    fontSize: 16.w,
                    color: "#232535".color,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    if (logic.isBatchMode.value) {
                      logic.toggleSelectAll();
                    } else {
                      logic.toggleBatchMode();
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 20.w),
                    child: Obx(() {
                      return Text(
                        logic.isBatchMode.value ? "全选" : "批量",
                        style: TextStyle(
                          fontSize: 13.w,
                          color: "#6C64FF".color,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          /// Tab 选择器
          _buildTabBar(),
        ],
      ),
    );
  }

  /// 构建 Tab 选择器
  Widget _buildTabBar() {
    return Container(
      height: 44.w,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() {
        if (logic.screenList.isEmpty) {
          return SizedBox.shrink();
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              logic.screenList.length,
              (index) => GestureDetector(
                onTap: () {
                  // 先更新 logic 的状态
                  logic.switchTab(index);
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.w,
                  ),
                  decoration: BoxDecoration(
                    color: logic.selectedTabIndex.value == index
                        ? "#DCEDFE".color
                        : '#E9F2F7'.color,
                    borderRadius: BorderRadius.circular(24.w),
                  ),
                  child: Text(
                    logic.screenList[index].name,
                    style: TextStyle(
                      fontSize: 14.w,
                      color: logic.selectedTabIndex.value == index
                          ? "#007BFE".color
                          : "#2A6181".color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
