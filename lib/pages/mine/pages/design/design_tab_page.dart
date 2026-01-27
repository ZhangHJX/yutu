import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'desigin_page_item.dart';
import '../../../widgets/page_empty_state.dart';
import '../../../model/common_model.dart';
import 'package:voicetemplate/core/index.dart';

/// 可保活的 Tab 页面组件
class DesignTabPage extends StatelessWidget {
  final int tagId;
  DesignTabPage({super.key, required this.tagId});
  final logic = Get.find<AppDesiginLogic>();

  @override
  Widget build(BuildContext context) {
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
      return Padding(
        padding: EdgeInsets.only(left: 15.w, right: 15.w, top: 12.w),
        child: SmartRefresher(
          controller: tabData.refreshController,
          enablePullUp: true,
          onRefresh: () async {
            await logic.onRefresh();
          },
          onLoading: () async {
            await logic.onLoad();
          },
          child: MasonryGridView.builder(
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 9.w,
            itemCount: designList.length,
            padding: EdgeInsetsDirectional.only(
              bottom: ScreenTools.bottomBarHeight,
            ),
            itemBuilder: (context, index) {
              final item = designList[index];
              // 使用独立的响应式组件，避免在 itemBuilder 中嵌套 Obx
              return _DesignItemWidget(item: item, logic: logic);
            },
          ),
        ),
      );
    });
  }
}

/// 独立的响应式 Item 组件，避免在 itemBuilder 中嵌套 Obx
class _DesignItemWidget extends StatelessWidget {
  final CommonItemModel item;
  final AppDesiginLogic logic;

  const _DesignItemWidget({required this.item, required this.logic});

  @override
  Widget build(BuildContext context) {
    // 只监听需要的响应式变量
    return Obx(() {
      final isSelected = item.isSelected;
      final showCheck = logic.isBatchMode.value;
      return DesiginPageItem(
        item: item,
        isSelected: isSelected,
        showCheck: showCheck,
        onTap: () {
          if (showCheck) {
            logic.toggleItemSelection(item.id);
          } else {
            Get.toNamed(
              AppRoutes.middle,
              arguments: {'id': item.id, "type": PageSource.design},
            );
          }
        },
        favoriteCallBack: () {
          if (!logic.global.isLogin) {
            Get.toNamed(AppRoutes.appLogin);
            return;
          }
          if (logic.isBatchMode.value) {
            return;
          }
          if (item.isFavorite == 1) {
            logic.favoriteEventDialog(item.id);
          } else {
            logic.clickFavorite(item.id, true);
          }
        },
      );
    });
  }
}
