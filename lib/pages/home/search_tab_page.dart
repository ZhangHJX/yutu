import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_logic.dart';
import '../widgets/page_empty_state.dart';
import 'widgets/home_page_item.dart';
import 'package:voicetemplate/core/index.dart';

/// 可保活的 Tab 页面组件
class SearchTabPage extends StatelessWidget {
  final int tagId;
  SearchTabPage({super.key, required this.tagId});
  final logic = Get.find<SearchLogic>();

  @override
  Widget build(BuildContext context) {
    final tabData = logic.tabDataMap[tagId];
    if (tabData == null) {
      return const PageEmptyState(title: '未找到匹配的模板~');
    }
    return Obx(() {
      // 使用多个独立的 Obx，避免嵌套
      final designList = tabData.dataList;
      final isLoading = tabData.isLoading.value;
      if (isLoading && designList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (designList.isEmpty) {
        return const PageEmptyState(title: '未找到匹配的模板~');
      }
      // 将响应式逻辑移到 itemBuilder 外部，使用独立的响应式 item 组件
      return SmartRefresher(
        key: tabData.refresherKey,
        controller: tabData.refreshController,
        enablePullUp: true,
        onRefresh: () async {
          await logic.onRefresh();
        },
        onLoading: () async {
          await logic.onLoadMore();
        },
        child: MasonryGridView.builder(
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 9.w,
          itemCount: designList.length,
          itemBuilder: (context, index) {
            final item = designList[index];
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
        ),
      );
    });
  }
}
