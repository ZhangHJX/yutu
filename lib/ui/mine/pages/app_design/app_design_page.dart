import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'design_bottom_bar.dart';
import 'desigin_page_item.dart';
import '../../../widgets/app_status_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AppDesignPage extends StatefulWidget {
  AppDesignPage({super.key});

  @override
  State<AppDesignPage> createState() => _AppDesignPageState();
}

class _AppDesignPageState extends State<AppDesignPage> {
  final logic = Get.put(AppDesiginLogic());
  late EasyRefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

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

              /// Tab 选择器
              _buildTabBar(),

              /// 1. 中间可滚动列表（用 Expanded 包起来）
              Expanded(
                child: Obx(() {
                  final isBatch = logic.isBatchMode.value;
                  if (logic.designList.isEmpty && !logic.isLoading.value) {
                    return Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(top: 89.w + 44.w),
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
                    child: EasyRefresh(
                      controller: _refreshController,
                      header: ClassicHeader(
                        showMessage: false,
                        triggerWhenReach: true,
                        dragText: '松开刷新',
                        readyText: '加载中...',
                        processingText: '加载中...',
                        processedText: '刷新完成',
                      ),
                      footer: ClassicFooter(
                        showMessage: false,
                        triggerWhenReach: true,
                        dragText: '上拉加载',
                        processingText: '加载中...',
                        processedText: '加载完成',
                        noMoreText: '没有更多了',
                      ),
                      onRefresh: () async {
                        await logic.onRefresh();
                        _refreshController.finishRefresh();
                      },
                      onLoad: logic.hasMore.value
                          ? () async {
                              await logic.onLoad();
                              _refreshController.finishLoad(
                                logic.hasMore.value
                                    ? IndicatorResult.success
                                    : IndicatorResult.noMore,
                              );
                            }
                          : null,
                      child: Obx(() {
                        return MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12.w,
                          crossAxisSpacing: 9.w,
                          padding: EdgeInsetsDirectional.zero,
                          itemCount: logic.designList.length,
                          itemBuilder: (context, index) {
                            final item = logic.designList[index];
                            return Obx(() {
                              final isSelected = logic.selectedIds.contains(
                                item.uuid,
                              );
                              return DesiginPageItem(
                                item: item,
                                showCheck: isBatch,
                                isSelected: isSelected,
                                onTap: () {
                                  if (isBatch) {
                                    logic.toggleItemSelection(item.uuid);
                                  } else {
                                    // 非批量模式下可以进入详情 / 编辑
                                    // Get.to(...);
                                  }
                                },
                              );
                            });
                          },
                        );
                      }),
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

  /// 构建 Tab 选择器
  Widget _buildTabBar() {
    return Container(
      height: 44.w,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Obx(() {
        if (logic.screenList.isEmpty) {
          return SizedBox.shrink();
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              logic.screenList.length,
              (index) => GestureDetector(
                onTap: () => logic.switchTab(index),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.w,
                  ),
                  decoration: BoxDecoration(
                    color: logic.selectedTabIndex.value == index
                        ? "#DCEDFE".color
                        : '#E9F2F7'.color,
                    borderRadius: BorderRadius.circular(24.w),
                  ),
                  child: Text(
                    logic.screenList[index].name,
                    style: TextStyle(
                      fontSize: 14.w,
                      color: logic.selectedTabIndex.value == index
                          ? "#007BFE".color
                          : "#2A6181".color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
