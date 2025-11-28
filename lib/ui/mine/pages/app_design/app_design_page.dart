import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'design_bottom_bar.dart';
import 'desigin_page_item.dart';
import '../widgets/app_status_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AppDesignPage extends StatelessWidget {
  AppDesignPage({super.key});

  final logic = Get.put(AppDesiginLogic());

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
                  "我的设计",
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

              /// 1. 中间可滚动列表（用 Expanded 包起来）
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
                          return DesiginPageItem(
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
                      DesignBottomBar(controller: logic),

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
