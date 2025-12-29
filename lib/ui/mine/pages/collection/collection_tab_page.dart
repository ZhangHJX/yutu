import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'collection_logic.dart';
import 'widgets/collection_page_item.dart';
import '../widgets/page_empty_state.dart';
import '../../model/common_model.dart';

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
      final designList = tabData.designList;
      final isLoading = tabData.isLoading.value;
      if (isLoading && designList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (designList.isEmpty) {
        return const PageEmptyState();
      }
      // 将响应式逻辑移到 itemBuilder 外部，使用独立的响应式 item 组件
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 9.w,
        padding: EdgeInsets.all(15.w),
        itemCount: designList.length,
        itemBuilder: (context, index) {
          final item = designList[index];
          // 使用独立的响应式组件，避免在 itemBuilder 中嵌套 Obx
          return _DesignItemWidget(item: item, logic: logic);
        },
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
        item: item,
        isSelected: isSelected,
        showCheck: showCheck,
        onTap: () {
          if (showCheck) {
            logic.toggleItemSelection("${item.id}");
          }
        },
      );
    });
  }
}
