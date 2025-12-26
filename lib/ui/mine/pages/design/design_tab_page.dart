import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'widgets/desigin_page_item.dart';
import '../widgets/page_empty_state.dart';

/// 可保活的 Tab 页面组件
class DesignTabPage extends StatelessWidget {
  DesignTabPage({super.key});

  final logic = Get.find<AppDesiginLogic>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tagId = logic.screenList[logic.selectedTabIndex.value].id;
      final tabData = logic.tabDataMap[tagId];
      if (tabData == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final designList = tabData.designList;
      final isLoading = tabData.isLoading.value;
      if (isLoading && designList.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }

      if (designList.isEmpty) {
        return const PageEmptyState();
      }

      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 9.w,
        padding: EdgeInsets.all(15.w),
        itemCount: designList.length,
        itemBuilder: (context, index) {
          final item = designList[index];
          return Obx(() {
            final isSelected = logic.selectedIds.contains('${item.id}');
            return DesiginPageItem(
              item: item,
              isSelected: isSelected,
              showCheck: logic.isBatchMode.value,
              onTap: () {
                if (logic.isBatchMode.value) {
                  logic.toggleItemSelection("${item.id}");
                }
              },
            );
          });
        },
      );
    });
  }
}
