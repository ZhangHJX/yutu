import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_logic.dart';
import './widgets/search_navigation_widget.dart';
import '../widgets/tab_item_widget.dart';
import '../widgets/page_empty_state.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'search_tab_page.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});
  final logic = Get.put(SearchLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: '#F5F5F5'.color,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F7F7), Color(0xFFE3EEF7)],
          ),
        ),
        child: Column(
          children: [
            // 顶部
            Obx(() {
              return SearchNavigationWidget(
                isEnabled: true,
                onSearch: (value) {},
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
                    return KeepAliveWrapper(child: SearchTabPage(tagId: tagId));
                  }),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Tab 选择器
  Widget _buildTabBar() {
    return Container(
      height: 44.w,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            logic.screenList.length,
            (index) => TabItemWidget(
              key: ValueKey('tab_item_$index'),
              name: logic.screenList[index].name,
              tapCallBack: () {
                logic.switchTab(index);
              },
              isSelected: logic.selectedTabIndex.value == index,
              selectColor: "#D8F5FF".color,
              unSelectColor: '#F4F4F4'.color,
              selectTextColor: '#007BFE'.color,
              unSelectTextColor: '#8D8D8D'.color,
            ),
          ),
        ),
      ),
    );
  }
}
