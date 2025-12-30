import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'search_logic.dart';
import '../widgets/page_empty_state.dart';
import './widgets/home_page_item.dart';
// import '../model/common_model.dart';

/// 可保活的 Tab 页面组件
class SearchTabPage extends StatelessWidget {
  final int tagId;
  SearchTabPage({super.key, required this.tagId});
  final logic = Get.find<SearchLogic>();

  @override
  Widget build(BuildContext context) {
    final tagId = logic.screenList[logic.selectedTabIndex.value].id;
    // final tabData = logic.tabDataMap[tagId];

    final tabData = {};
    if (tabData == null) {
      return const PageEmptyState();
    }

    // 使用多个独立的 Obx，避免嵌套
    // return Obx(() {
    // final designList = tabData.dataList;
    // final isLoading = tabData.dataList.value;

    final designList = [];
    final isLoading = true;

    if (isLoading && designList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (designList.isEmpty) {
      return const PageEmptyState();
    }
    // 将响应式逻辑移到 itemBuilder 外部，使用独立的响应式 item 组件
    return Padding(
      padding: EdgeInsets.only(left: 15.w, right: 15.w, top: 12.w),
      child: SmartRefresher(
        key: logic.refresherKey,
        controller: logic.refreshController,
        enablePullDown: true,
        // enablePullUp: logic.hasMore.value,
        header: ClassicHeader(
          refreshStyle: RefreshStyle.Follow, // 或 RefreshStyle.Behind
        ),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
          completeDuration: Duration(milliseconds: 500),
        ),
        onRefresh: () async {
          // await logic.onRefresh();
        },
        onLoading: () async {
          // await logic.onLoad();
        },
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 9.w,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsetsDirectional.only(
            bottom: ScreenTools.bottomBarHeight,
          ),
          itemCount: designList.length,
          itemBuilder: (context, index) {
            final item = designList[index];
            // 使用独立的响应式组件，避免在 itemBuilder 中嵌套 Obx
            // return _DesignItemWidget(item: item);
            return _DesignItemWidget();
          },
        ),
      ),
    );
    // });
  }
}

/// 独立的响应式 Item 组件，避免在 itemBuilder 中嵌套 Obx
class _DesignItemWidget extends StatelessWidget {
  // final CommonItemModel item;

  // const _DesignItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    // 只监听需要的响应式变量
    return Obx(() {
      // final isSelected = logic.selectedIds.contains('${item.id}');
      return HomePageItem(
        // key: ValueKey(item.id),
        onTap: () {
          // if (showCheck) {
          //   logic.toggleItemSelection("${item.id}");
          // }
        },
        imageH: 60,
        imageUrl: '',
        title: '',
        type: '',
        favorite: 99,
      );
    });
  }
}
