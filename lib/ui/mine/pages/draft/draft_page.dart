import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/ui/mine/pages/widgets/page_empty_state.dart';

import '../widgets/operation_bottom_bar.dart';
import '../widgets/top_navigation_widget.dart';
import '../widgets/storage_space_card.dart';
import 'draft_page_item.dart';
import 'draft_logic.dart';

class AppDraftPage extends StatelessWidget {
  AppDraftPage({super.key});

  final logic = Get.put(DraftLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9ADEFD),
              Color(0xFFF7F7F7),
              Color(0xFFF7F7F7),
              Color(0xFFE3EEF7),
            ],
            stops: [0.0, 0.2, 0.2, 1.0],
          ),
        ),
        child: Column(
          children: [
            Obx(() {
              return TopNavigationWidget(
                title: "我的草稿",
                rightTitle: logic.isBatchMode.value ? "全选" : "批量",
                onTap: () {
                  if (logic.isBatchMode.value) {
                    logic.toggleSelectAll();
                  } else {
                    logic.toggleBatchMode();
                  }
                },
              );
            }),

            SizedBox(height: 7.w),

            /// 1. 存储空间组件
            StorageSpaceCard(),
            SizedBox(height: 10.w),

            /// 2. 中间可滚动列表（用 Expanded 包起来）
            Expanded(
              child: Obx(() {
                final isBatch = logic.isBatchMode.value;
                if (logic.draftList.isEmpty) return PageEmptyState();

                return Container(
                  color: Colors.transparent,
                  margin: EdgeInsets.symmetric(horizontal: 15.w),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.w,
                    crossAxisSpacing: 9.w,
                    padding: EdgeInsetsDirectional.zero,
                    itemCount: logic.draftList.length,
                    itemBuilder: (context, index) {
                      final item = logic.draftList[index];
                      return Obx(() {
                        final isSelected = logic.selectedIds.contains(item.id);
                        return DraftPageItem(
                          item: item,
                          showCheck: isBatch,
                          isSelected: isSelected,
                          onTap: () {
                            if (isBatch) {
                              // logic.toggleItemSelection(item.id);
                            } else {
                              // 非批量模式下可以进入详情 / 编辑
                              // Get.to(...);
                            }
                          },
                        );
                      });
                    },
                  ),
                );
              }),
            ),

            /// 3. 底部操作栏（全选 / 取消 / 删除）
            Obx(
              () => Column(
                children: [
                  if (logic.isBatchMode.value)
                    OperationBottomBar(
                      cancelEvent: logic.clearSelection,
                      deleteEvent: logic.deleteSelected,
                      typeName: "草稿",
                    ),

                  if (ScreenTools.bottomBarHeight > 0 &&
                      logic.isBatchMode.value)
                    Container(
                      color: Colors.white,
                      height: ScreenTools.bottomBarHeight,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
