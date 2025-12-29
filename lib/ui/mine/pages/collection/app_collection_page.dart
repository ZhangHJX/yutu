import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'collection_logic.dart';
import '../widgets/operation_bottom_bar.dart';
import '../widgets/page_empty_state.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import '../widgets/tab_item_widget.dart';
import '../widgets/top_navigation_widget.dart';
import 'collection_tab_page.dart';

class AppCollectionPage extends StatelessWidget {
  AppCollectionPage({super.key});
  final logic = Get.put(CollectionLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: '#F5F5F5'.color,
      body: DecoratedBox(
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
            stops: [0.0, 0.1, 0.1, 1.0],
          ),
        ),
        child: Column(
          children: [
            // 顶部
            Obx(() {
              return TopNavigationWidget(
                title: "我的收藏",
                rightTitle: logic.isBatchMode.value ? "全选" : "批量",
                onTap: () {
                  if (logic.isBatchMode.value) {
                    logic.toggleSelectAll();
                  } else {
                    logic.toggleBatchMode();
                  }
                },
                children: [_buildTabBar()],
              );
            }),

            Expanded(
              child: Obx(() {
                // 如果screenList为空或TabController未初始化，显示加载状态
                if (logic.screenList.isEmpty && logic.tabIsLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (logic.tabController.value == null) {
                    return const PageEmptyState();
                  }
                }
                return TabBarView(
                  controller: logic.tabController.value!,
                  children: List.generate(logic.screenList.length, (index) {
                    final tagId = logic.screenList[index].id;
                    return KeepAliveWrapper(
                      child: CollectionTabPage(tagId: tagId),
                    );
                  }),
                );
              }),
            ),

            /// 底部操作栏（全选 / 取消 / 删除）
            Obx(
              () => Column(
                children: [
                  if (logic.isBatchMode.value)
                    OperationBottomBar(
                      cancelEvent: logic.clearSelection,
                      deleteEvent: logic.deleteSelected,
                      typeName: "收藏",
                    ),
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
        ),
      ),
    );
  }

  // 构建 Tab 选择器
  Widget _buildTabBar() {
    return Container(
      height: 44.w,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() {
        if (logic.screenList.isEmpty) {
          return const SizedBox.shrink();
        }
        // 移除内层嵌套的 Obx，外层 Obx 已经监听了 screenList 和 selectedTabIndex
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              logic.screenList.length,
              (index) => TabItemWidget(
                name: logic.screenList[index].name,
                tapCallBack: () {
                  logic.switchTab(index);
                },
                isSelected: logic.selectedTabIndex.value == index,
              ),
            ),
          ),
        );
      }),
    );
  }
}
