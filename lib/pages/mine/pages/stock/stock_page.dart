import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'stock_logic.dart';
import 'stock_page_item.dart';
import '../widgets/storage_space_card.dart';
import '../widgets/operation_bottom_bar.dart';
import '../../../widgets/page_empty_state.dart';
import '../widgets/top_navigation_widget.dart';

class AppStockPage extends StatelessWidget {
  AppStockPage({super.key});
  final logic = Get.put(StockLogic());

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
                title: "我的素材",
                rightTitle: logic.isBatchMode.value ? "全选" : "批量",
                onTap: () {
                  if (logic.stockList.isEmpty) {
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
              final userInfo = logic.global.userInfo.value;

              final materialSize = userInfo.materialSize;
              final materialSizeLimit = userInfo.materialSizeLimit;
              final usageRatio =
                  materialSize /
                  (materialSizeLimit > 0 ? materialSizeLimit : 1);
              return StorageSpaceCard(
                usageRatio: usageRatio,
                sizeLimit: materialSizeLimit,
                fileSize: materialSize,
              );
            }),

            SizedBox(height: 10.w),

            /// 2. 中间可滚动列表（用 Expanded 包起来）
            Expanded(
              child: Obx(() {
                if (logic.stockList.isEmpty && !logic.isLoading.value) {
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
                    header: ClassicHeader(),
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
                      itemCount: logic.stockList.length,
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemBuilder: (context, index) {
                        final item = logic.stockList[index];

                        return Obx(() {
                          final isBatch = logic.isBatchMode.value;
                          final isSelected = logic.selectedIds.contains(
                            '${item.id}',
                          );
                          return StockPageItem(
                            item: item,
                            showCheck: isBatch,
                            isSelected: isSelected,
                            onTap: () {
                              if (isBatch) {
                                logic.toggleItemSelection('${item.id}');
                              } else {
                                // 非批量模式下可以进入详情 / 编辑
                                // Get.to(...);
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
                      deleteEvent: logic.deleteSelected,
                      typeName: "素材",
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
