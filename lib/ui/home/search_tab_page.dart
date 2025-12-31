import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_logic.dart';
import '../widgets/page_empty_state.dart';
import './widgets/home_page_item.dart';
import '../model/common_model.dart';

/// 可保活的 Tab 页面组件
class SearchTabPage extends StatelessWidget {
  final int tagId;
  SearchTabPage({super.key, required this.tagId});
  final logic = Get.find<SearchLogic>();

  @override
  Widget build(BuildContext context) {
    final tagId = logic.screenList[logic.selectedTabIndex.value].id;
    final tabData = logic.tabDataMap[tagId];
    if (tabData == null) {
      return const PageEmptyState();
    }

    // 使用多个独立的 Obx，避免嵌套
    return Obx(() {
      final designList = tabData.dataList;
      final isLoading = tabData.isLoading.value;
      if (isLoading && designList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (designList.isEmpty) {
        return const PageEmptyState();
      }
      // 将响应式逻辑移到 itemBuilder 外部，使用独立的响应式 item 组件
      return SmartRefresher(
        key: tabData.refresherKey,
        controller: tabData.refreshController,
        enablePullDown: true,
        enablePullUp: logic.hasMore.value,
        header: ClassicHeader(
          refreshStyle: RefreshStyle.Follow, // 或 RefreshStyle.Behind
        ),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
          completeDuration: Duration(milliseconds: 500),
        ),
        onRefresh: () async {
          await logic.onRefresh();
        },
        onLoading: () async {
          await logic.onLoad();
        },
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 9.w,
          padding: EdgeInsets.all(15.w),
          itemCount: designList.length,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            final item = designList[index];
            // 使用独立的响应式组件，避免在 itemBuilder 中嵌套 Obx
            return _DesignItemWidget(item: item, logic: logic);
          },
        ),
      );
    });
  }
}

/// 独立的响应式 Item 组件，避免在 itemBuilder 中嵌套 Obx
class _DesignItemWidget extends StatelessWidget {
  final CommonItemModel item;
  final SearchLogic logic;

  const _DesignItemWidget({required this.item, required this.logic});

  @override
  Widget build(BuildContext context) {
    final itemWidth = (ScreenTools.screenWidth - 30.w - 9.w) / 2;
    final itemHeight = calculateAspectRatio(itemWidth, item.canvasSize ?? '');
    // 只监听需要的响应式变量
    return HomePageItem(
      key: ValueKey(item.id),
      onTap: () {
        // 可以在这里添加点击跳转逻辑
      },
      imageH: itemHeight,
      imageUrl: '${item.originalImage}${item.thumbnail}',
      title: item.title ?? '',
      type: 1,
      favorite: item.favoriteTotal ?? 0,
    );
  }
}
