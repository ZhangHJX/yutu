import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'collection_logic.dart';
import 'collection_page_item.dart';
import '../../../widgets/page_empty_state.dart';
import '../../../model/common_model.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'package:voicetemplate/app/routes/index.dart';

/// 可保活的 Tab 页面组件
class CollectionTabPage extends StatelessWidget {
  final int tagId;
  CollectionTabPage({super.key, required this.tagId});
  final logic = Get.find<CollectionLogic>();

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
  final CollectionLogic logic;

  const _DesignItemWidget({required this.item, required this.logic});

  @override
  Widget build(BuildContext context) {
    // 只监听需要的响应式变量
    return Obx(() {
      final isSelected = logic.selectedIds.contains('${item.id}');
      final showCheck = logic.isBatchMode.value;
      return CollectionPageItem(
        key: ValueKey(item.id), // ⭐️加上
        item: item,
        isSelected: isSelected,
        showCheck: showCheck,
        onTap: () {
          if (showCheck) {
            logic.toggleItemSelection("${item.id}");
          } else {
            Get.toNamed(
              AppRoutes.middle,
              arguments: {'id': item.id, "type": PageSource.design},
            );
          }
        },
        favoriteCallBack: () {
          if (item.isFavorite == 1) {
            logic.toggleItemSelection("${item.id}");
            SmartDialog.show(
              builder: (context) => ConfirmPopWidget(
                title: '温馨提示',
                subTitle: '确定要取消收藏吗？',
                sureAction: logic.deleteSelected,
              ),
              alignment: Alignment.center,
              animationType: SmartAnimationType.centerFade_otherSlide,
              animationTime: Duration(milliseconds: 250),
              maskColor: "#000000".color.withValues(alpha: 0.5),
              clickMaskDismiss: false,
              useAnimation: true,
              usePenetrate: false,
            );
          }
        },
      );
    });
  }
}
