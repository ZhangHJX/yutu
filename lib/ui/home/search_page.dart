import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_logic.dart';
import './widgets/search_navigation_widget.dart';
import '../widgets/page_empty_state.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'search_tab_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final logic = Get.put(SearchLogic());

  @override
  void initState() {
    super.initState();
  }

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
            SearchNavigationWidget(
              isEnabled: true,
              onSearch: (value) {
                logic.searchText.value = value;
                logic.onRefresh();
              },
              onClear: () {
                logic.searchText.value = '';
                logic.onRefresh();
              },
              child: _buildTabBar(),
            ),
            Expanded(
              child: Obx(() {
                final list = logic.screenList;

                debugPrint(
                  '=${list.isEmpty}=======${logic.tabIsLoading.value}========',
                );

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
    );
  }

  /// 构建 Tab 选择器
  Widget _buildTabBar() {
    return Obx(() {
      // 将可观察变量赋值给局部变量，确保 GetX 能追踪到
      final screenList = logic.screenList;
      final tabController = logic.tabController.value;
      // 如果列表为空或 TabController 未初始化，返回空容器
      if (screenList.isEmpty || tabController == null) {
        return SizedBox(height: 44.w);
      }
      return Container(
        height: 44.w,
        color: Colors.transparent,
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        child: AnimatedBuilder(
          animation: tabController,
          builder: (context, child) {
            return TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start, // ⭐ 防止某些场景默认不是start
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              indicator: const BoxDecoration(),
              dividerColor: Colors.transparent,
              labelColor: '#007BFE'.color,
              unselectedLabelColor: '#8D8D8D'.color,
              labelStyle: TextStyle(
                fontSize: 14.w,
                fontWeight: FontWeight.w400,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14.w,
                fontWeight: FontWeight.w400,
              ),
              onTap: (index) {
                logic.switchTab(index);
              },
              tabs: List.generate(screenList.length, (index) {
                final item = screenList[index];
                final isSelected = tabController.index == index;
                return Container(
                  margin: EdgeInsets.only(
                    right: paddingWithTab(index, screenList.length - 1),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 9.w),
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isSelected ? '#D8F5FF'.color : '#F4F4F4'.color,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Center(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: isSelected ? '#007BFE'.color : '#8D8D8D'.color,
                        fontSize: 14.w,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      );
    });
  }

  double paddingWithTab(int index, int total) {
    if (index > 0 && index < total) {
      return 12.w;
    }
    return 0;
  }
}
