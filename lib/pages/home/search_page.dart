import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_logic.dart';
import 'widgets/search_navigation_widget.dart';
import '../widgets/page_empty_state.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'search_tab_page.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final logic = Get.put(SearchLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: '#F7F7F7'.color,
      body: SafeArea(
        bottom: false,
        child: Container(
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
              SearchNavigationWidget(
                onSearch: (value) {
                  logic.searchText.value = value;
                  logic.onRefresh();
                },
                onClear: () {
                  logic.searchText.value = '';
                  logic.onRefresh();
                },
                onChanged: (value) {
                  if (value.isEmpty) {
                    FocusManager.instance.primaryFocus?.unfocus(); // 收起键盘
                    logic.searchText.value = '';
                  }
                },
              ),

              Obx(() {
                return AutoScrollTabBar(
                  screenList: logic.screenList,
                  tabController: logic.tabController.value,
                  onTabTap: (index) => logic.switchTab(index),
                );
              }),

              Expanded(
                child: Obx(() {
                  final list = logic.screenList;
                  // 如果screenList为空或TabController未初始化，显示加载状态
                  if (list.isEmpty && logic.tabIsLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    if (logic.tabController.value == null) {
                      return const PageEmptyState(title: '未找到匹配的模板~');
                    }
                  }
                  return TabBarView(
                    controller: logic.tabController.value!,
                    children: List.generate(logic.screenList.length, (index) {
                      final tagId = logic.screenList[index].id;
                      return KeepAliveWrapper(
                        key: ValueKey('search_page_$tagId'),
                        child: SearchTabPage(
                          key: ValueKey('search_page_$tagId'),
                          tagId: tagId,
                        ),
                      );
                    }),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
