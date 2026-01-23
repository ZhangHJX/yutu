import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../../widgets/page_empty_state.dart';
import '../widgets/operation_bottom_bar.dart';
import '../widgets/top_navigation_widget.dart';
import '../widgets/storage_space_card.dart';
import 'package:voicetemplate/core/index.dart';
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
            stops: [0.0, 0.1, 0.1, 1.0],
          ),
        ),
        child: Column(
          children: [
            Obx(() {
              return TopNavigationWidget(
                title: "我的草稿",
                rightTitle: logic.isBatchMode.value ? "全选" : "批量",
                onTap: () {
                  if (logic.draftList.isEmpty) {
                    showToast("当前无数据，无法处理");
                    return;
                  }
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
            Obx(() {
              final userInfo = logic.userInfo.value;
              final draftSize = userInfo.draftSize;
              final draftSizeLimit = userInfo.draftSizeLimit;
              final usageRatio =
                  draftSize / (draftSizeLimit > 0 ? draftSizeLimit : 1);

              return StorageSpaceCard(
                usageRatio: usageRatio,
                sizeLimit: draftSizeLimit,
                fileSize: draftSize,
              );
            }),
            SizedBox(height: 10.w),

            /// 2. 中间可滚动列表（用 Expanded 包起来）
            Expanded(
              child: Obx(() {
                if (logic.draftList.isEmpty && !logic.isLoading.value) {
                  return PageEmptyState();
                }
                return Padding(
                  padding: EdgeInsets.only(
                    left: 15.w,
                    right: 15.w,
                    bottom: ScreenTools.bottomBarHeight,
                  ),
                  child: SmartRefresher(
                    key: logic.refresherKey,
                    controller: logic.refreshController,
                    enablePullUp: true,
                    onRefresh: () async {
                      await logic.onRefresh();
                    },
                    onLoading: () async {
                      await logic.onLoad();
                    },
                    child: MasonryGridView.builder(
                      gridDelegate:
                          SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                          ),
                      mainAxisSpacing: 12.w,
                      crossAxisSpacing: 9.w,
                      itemCount: logic.draftList.length,
                      itemBuilder: (context, index) {
                        final item = logic.draftList[index];
                        return Obx(() {
                          final isBatch = logic.isBatchMode.value;
                          final isSelected = logic.selectedIds.contains(
                            '${item.id}',
                          );
                          return DraftPageItem(
                            item: item,
                            showCheck: isBatch,
                            isSelected: isSelected,
                            onTap: () {
                              if (isBatch) {
                                logic.toggleItemSelection('${item.id}');
                              } else {
                                Get.toNamed(
                                  AppRoutes.middle,
                                  arguments: {
                                    'id': item.id,
                                    "type": PageSource.draft,
                                  },
                                );
                              }
                            },
                            index: index,
                          );
                        });
                      },
                    ),
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
                      deleteEvent: () {
                        SmartDialog.dismiss();
                        logic.deleteSelected();
                      },
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
