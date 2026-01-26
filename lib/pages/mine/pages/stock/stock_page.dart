import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'stock_logic.dart';
import 'stock_page_item.dart';
import '../widgets/storage_space_card.dart';
import '../widgets/operation_bottom_bar.dart';
import '../../../widgets/page_empty_state.dart';
import '../widgets/top_navigation_widget.dart';

class AppStockPage extends StatefulWidget {
  const AppStockPage({super.key});

  @override
  State<AppStockPage> createState() => _AppStockPageState();
}

class _AppStockPageState extends State<AppStockPage> {
  late final StockLogic logic;
  late final RefreshController _refreshController;
  bool isFirstInit = true;

  @override
  void initState() {
    super.initState();
    logic = Get.put(StockLogic());
    _refreshController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isFirstInit) {
        isFirstInit = false;
        _onRefresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await logic.loadDataList(refresh: true);
    if (!mounted) return;
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
              final userInfo = logic.userInfo.value;
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
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                enablePullUp: true,
                onRefresh: _onRefresh,
                onLoading: _onLoading,
                child: CustomScrollView(
                  slivers: [
                    Obx(() {
                      final list = logic.stockList;
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
