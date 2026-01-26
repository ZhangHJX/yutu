import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../../widgets/page_empty_state.dart';
import '../widgets/operation_bottom_bar.dart';
import '../widgets/top_navigation_widget.dart';
import '../widgets/storage_space_card.dart';
import 'package:voicetemplate/core/index.dart';
import 'draft_page_item.dart';
import 'draft_logic.dart';

class AppDraftPage extends StatefulWidget {
  const AppDraftPage({super.key});

  @override
  State<AppDraftPage> createState() => _AppDraftPageState();
}

class _AppDraftPageState extends State<AppDraftPage> {
  late final DraftLogic logic;
  late final RefreshController _refreshController;
  bool isFirstInit = true;

  @override
  void initState() {
    super.initState();
    logic = Get.put(DraftLogic());
    _refreshController = RefreshController();
    // _onRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isFirstInit) {
        isFirstInit = false;
        _onRefresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose(); // ✅ controller 跟页面一起释放
    // Get.delete<DraftLogic>(force: true); // ✅ 如需销毁 logic（看你是否全局复用）
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await logic.loadDataList(refresh: true);
    if (!mounted) return; // ✅ 避免页面已销毁还回调
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    await logic.loadDataList();
    if (!mounted) return;
    if (logic.hasMore.value) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

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
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                enablePullUp: true,
                onRefresh: _onRefresh,
                onLoading: _onLoading,
                child: CustomScrollView(
                  slivers: [
                    Obx(() {
                      final list = logic.draftList;
                      final isLoading = logic.isLoading.value;

                      if (list.isEmpty && !isLoading) {
                        return SliverToBoxAdapter(child: PageEmptyState());
                      }

                      return SliverPadding(
                        padding: EdgeInsets.only(
                          left: 15.w,
                          right: 15.w,
                          bottom: ScreenTools.bottomBarHeight,
                        ),
                        sliver: SliverMasonryGrid(
                          gridDelegate:
                              const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                          mainAxisSpacing: 12.w,
                          crossAxisSpacing: 9.w,
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = list[index];
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
                          }, childCount: list.length),
                        ),
                      );
                    }),
                  ],
                ),
              ),
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
