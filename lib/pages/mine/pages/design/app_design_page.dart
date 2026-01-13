import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'design_tab_page.dart';
// import '../../../widgets/tab_item_widget.dart';
import '../widgets/operation_bottom_bar.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import '../widgets/top_navigation_widget.dart';
import '../../../widgets/page_empty_state.dart';
import 'package:voicetemplate/pages/mine/pages/widgets/mine_scroll_tab_bar.dart';

class AppDesignPage extends StatelessWidget {
  AppDesignPage({super.key});
  final logic = Get.put(AppDesiginLogic());

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
            stops: [0.0, 0.15, 0.15, 1.0],
          ),
        ),
        child: Column(
          children: [
            // 顶部
            Obx(() {
              return TopNavigationWidget(
                title: "我的设计",
                rightTitle: logic.isBatchMode.value ? "全选" : "批量",
                onTap: () {
                  if (logic.isBatchMode.value) {
                    logic.toggleSelectAll();
                  } else {
                    logic.toggleBatchMode();
                  }
                },
                child: Obx(
                  () => MineScrollTabBar(
                    screenList: logic.screenList,
                    tabController: logic.tabController.value,
                    onTabTap: (index) => logic.switchTab(index),
                  ),
                ),
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
                      key: ValueKey('design_page_$tagId'),
                      child: DesignTabPage(
                        key: ValueKey('design_page_$tagId'),
                        tagId: tagId,
                      ),
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
                      typeName: "设计",
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
}
