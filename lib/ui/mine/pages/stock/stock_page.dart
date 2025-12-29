import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'stock_logic.dart';
import 'stock_page_item.dart';
import '../widgets/storage_space_card.dart';
import '../widgets/app_status_bar.dart';
import '../widgets/operation_bottom_bar.dart';

class AppStockPage extends StatelessWidget {
  AppStockPage({super.key});

  final logic = Get.put(StockLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      body: Stack(
        children: [
          AppStatusBar(),
          Column(
            children: [
              CAppBar(
                title: Text(
                  "我的素材",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.transparent,
                actions: [
                  GestureDetector(
                    onTap: () {
                      if (logic.isBatchMode.value) {
                        logic.toggleSelectAll();
                      } else {
                        logic.toggleBatchMode();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: 20.w),
                      child: Obx(() {
                        return Text(
                          logic.isBatchMode.value ? "全选" : "批量",
                          style: TextStyle(
                            fontSize: 13.w,
                            color: "#6C64FF".color,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 7.w),

              /// 1. 存储空间组件
              // StorageSpaceCard(controller: logic),
              SizedBox(height: 10.w),

              /// 2. 中间可滚动列表（用 Expanded 包起来）
              Expanded(
                child: Obx(() {
                  final isBatch = logic.isBatchMode.value;

                  if (logic.drafts.isEmpty) {
                    return Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(top: 89.w),
                      child: Stack(
                        children: [
                          Image.asset(
                            "assets/images/mine/app_resource_empty.png",
                            width: 146.w,
                            height: 146.w,
                            fit: BoxFit.cover,
                          ),

                          Positioned(
                            top: 130.w,
                            child: SizedBox(
                              width: 146.w,
                              child: Center(
                                child: Text(
                                  "暂无内容",
                                  style: TextStyle(
                                    fontSize: 12.w,
                                    color: "#9E9E9E".color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    color: Colors.transparent,
                    margin: EdgeInsets.symmetric(horizontal: 15.w),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.w,
                      crossAxisSpacing: 9.w,
                      padding: EdgeInsetsDirectional.zero,
                      itemCount: logic.drafts.length,
                      itemBuilder: (context, index) {
                        final item = logic.drafts[index];
                        return Obx(() {
                          final isSelected = logic.selectedIds.contains(
                            item.id,
                          );
                          return StockPageItem(
                            item: item,
                            showCheck: isBatch,
                            isSelected: isSelected,
                            onTap: () {
                              if (isBatch) {
                                logic.toggleItemSelection(item.id);
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
                        typeName: "设计",
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
        ],
      ),
    );
  }
}
