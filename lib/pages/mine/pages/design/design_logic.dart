import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/pages/model/index.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/core/index.dart';

class AppDesiginLogic extends GetxController with GetTickerProviderStateMixin {
  final global = Get.find<GlobalLogic>();

  /// 头部的tab
  final screenList = <ScreenItemModel>[].obs;
  // 当前选中的 tab 索引
  final RxInt selectedTabIndex = 0.obs;
  // 每个 tab 的数据状态（使用 tagId 作为 key，0 表示全部）
  final Map<int, TabDataState> tabDataMap = {};

  /// TabController
  final Rxn<TabController> tabController = Rxn<TabController>();

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;
  final RxBool isAllSelected = false.obs;
  final RxBool tabIsLoading = false.obs;

  /// 获取当前 tab 的数据列表
  RxList<CommonItemModel> get designList {
    final tagId = _getCurrentTagId();
    return tabDataMap[tagId]?.dataList ?? <CommonItemModel>[].obs;
  }

  /// 获取当前 tab 是否正在加载
  RxBool get isLoading {
    final tagId = _getCurrentTagId();
    return tabDataMap[tagId]?.isLoading ?? false.obs;
  }

  /// 获取当前 tab 是否还有更多数据
  RxBool get hasMore {
    final tagId = _getCurrentTagId();
    return tabDataMap[tagId]?.hasMore ?? true.obs;
  }

  @override
  void onReady() {
    super.onReady();
    if (global.connectStatus.currentStatus == NetworkStatus.none) {
      showToast("打开失败");
      return;
    }
  }

  /// 初始化一些假数据
  @override
  void onInit() {
    super.onInit();
    getTabTags();
  }

  @override
  void onClose() {
    // 清理 TabController
    tabController.value?.removeListener(_onTabControllerChanged);
    tabController.value?.dispose();
    tabController.value = null;
    // 释放所有 tab 的 RefreshController
    for (var tabData in tabDataMap.values) {
      tabData.refreshController.dispose();
    }
    tabDataMap.clear();
    super.onClose();
  }

  /// 创建或更新 TabController
  void createTabController() {
    final newLength = screenList.length;
    if (newLength == 0) return;
    // 创建新的 TabController
    final newController = TabController(
      length: newLength,
      vsync: this,
      initialIndex: 0,
    );
    newController.addListener(_onTabControllerChanged);
    tabController.value = newController;
    selectedTabIndex.value = 0;
  }

  /// TabController 切换监听
  void _onTabControllerChanged() {
    final controller = tabController.value;
    if (controller == null) return;

    if (!controller.indexIsChanging) {
      final index = controller.index;
      // 避免循环调用：只有当索引不同时才更新
      if (index != selectedTabIndex.value) {
        // 直接更新索引，避免再次触发 TabController 的 animateTo
        selectedTabIndex.value = index;
        // 切换 tab 时，如果该 tab 未初始化，则加载数据
        final tagId = _getCurrentTagId();
        final tabData = _getOrCreateTabData(tagId);
        if (!tabData.isInitialized) {
          loadDesignList(refresh: true);
        }
      }
    }
  }

  /// 切换 tab（由外部调用，如点击 Tab 按钮）
  void switchTab(int index) {
    if (index < 0 || screenList.isEmpty || index >= screenList.length) {
      return;
    }
    if (selectedTabIndex.value == index) return;
    // 更新选中索引
    selectedTabIndex.value = index;

    // 同步 TabController 的索引（如果不同步）
    final controller = tabController.value;
    if (controller != null && controller.index != index) {
      controller.animateTo(index);
    }

    // 切换 tab 时，如果该 tab 未初始化，则加载数据
    final tagId = _getCurrentTagId();
    final tabData = _getOrCreateTabData(tagId);
    if (!tabData.isInitialized) {
      loadDesignList(refresh: true);
    }
  }

  /// 风格标签
  Future<void> getTabTags() async {
    try {
      tabIsLoading.value = true;
      final result = await http.post('/tag/index');
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        final model = ScreenItemModel(id: 0, name: '全部');
        listModel.items.insert(0, model);
        screenList.value = listModel.items;

        // 创建 TabController
        createTabController();

        /// 刚进来的时候传全部
        await onRefresh();
      }
      tabIsLoading.value = false;
    } catch (e) {
      tabIsLoading.value = false;
      AppLogger.error('获取场景数据失败:', e);
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadDesignList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad({int? tagId}) async {
    await loadDesignList(refresh: false);
  }

  /// 获取当前 tab 的 tagId
  int _getCurrentTagId() {
    if (screenList.isEmpty || selectedTabIndex.value >= screenList.length) {
      return 0;
    }
    return screenList[selectedTabIndex.value].id;
  }

  /// 获取或创建 tab 数据状态
  TabDataState _getOrCreateTabData(int tagId) {
    if (!tabDataMap.containsKey(tagId)) {
      tabDataMap[tagId] = TabDataState();
    }
    return tabDataMap[tagId]!;
  }

  /// 加载图片列表
  Future<void> loadDesignList({bool refresh = false}) async {
    // 确定要加载的 tagId
    final targetTagId = _getCurrentTagId();
    final tabData = _getOrCreateTabData(targetTagId);
    if (tabData.isLoading.value) {
      return;
    }
    if (refresh) {
      tabData.currentPage = 1;
    }
    tabData.isLoading.value = true;
    try {
      final result = await http.get(
        '/design/index',
        query: {
          'page': '${tabData.currentPage}',
          'limit': globalPageSize,
          'tag_id': targetTagId,
        },
      );

      if (result.code == 0 && result.data != null) {
        final listModel = CommonModel.fromJson(result.data);
        if (tabData.currentPage == 1) {
          tabData.dataList.clear();
        }
        if (listModel.items.isNotEmpty) {
          final itemsToAdd = isAllSelected.value
              ? listModel.items
                    .map((e) => e.copyWith(isSelected: true))
                    .toList()
              : listModel.items;

          tabData.dataList.addAll(itemsToAdd);
          tabData.currentPage++;
          tabData.hasMore.value = true;
        } else {
          tabData.hasMore.value = false;
        }
        tabData.isInitialized = true;
      }

      tabData.isLoading.value = false;
    } catch (e) {
      tabData.isLoading.value = false;
      AppLogger.error('列表数据请求错误:', e);
    } finally {
      if (!isClosed) {
        if (refresh) {
          tabData.refreshController.refreshCompleted();
        } else {
          if (hasMore.value) {
            tabData.refreshController.loadComplete();
          } else {
            tabData.refreshController.loadNoData();
          }
        }
      }
    }
  }

  /// 切换批量模式
  void toggleBatchMode() {
    isBatchMode.toggle();
    if (!isBatchMode.value) {
      clearSelection();
    }
  }

  /// 单个 item 选中 / 取消
  void toggleItemSelection(int id) {
    bool tempSeletedAll = true;

    for (final tabState in tabDataMap.values) {
      tabState.dataList.assignAll(
        tabState.dataList.map((e) {
          bool selecteStatus = e.isSelected;
          if (e.id == id) {
            selecteStatus = !selecteStatus;
          }
          if (!selecteStatus) {
            tempSeletedAll = false;
          }
          return e.copyWith(isSelected: selecteStatus);
        }).toList(),
      );
    }

    isAllSelected.value = tempSeletedAll;
  }

  /// 全选
  void toggleSelectAll() {
    isAllSelected.value = true;
    for (final tabState in tabDataMap.values) {
      tabState.dataList.assignAll(
        tabState.dataList.map((e) => e.copyWith(isSelected: true)).toList(),
      );
    }
  }

  /// 取消
  void clearSelection() {
    isBatchMode.value = false;
    isAllSelected.value = false;
    for (final tabState in tabDataMap.values) {
      tabState.dataList.assignAll(
        tabState.dataList.map((e) => e.copyWith(isSelected: false)).toList(),
      );
    }
  }

  /// 删除选中的设计
  Future<void> deleteSelected() async {
    if (global.connectStatus.currentStatus == NetworkStatus.none) {
      showToast("删除失败");
      return;
    }

    final selectedIds = tabDataMap.values
        .expand((tabState) => tabState.dataList)
        .where((e) => e.isSelected == true)
        .map((e) => e.id)
        .toSet()
        .toList();

    if (selectedIds.isEmpty) {
      showToast("未选中要删除的数据");
      return;
    }

    try {
      showLoading("删除中");
      // 发送删除请求，将选中的uuid列表作为参数
      final result = await http.post(
        '/design/destroys',
        data: {
          'ids': selectedIds.join(','),
          'is_all': isAllSelected.value ? 1 : 0,
        },
      );

      if (result.code == 0) {
        // 删除成功，从当前tab的数据列表中移除已删除的项
        for (final tabState in tabDataMap.values) {
          tabState.dataList.removeWhere((e) => selectedIds.contains(e.id));
        }
        // 清除选择并退出批量模式
        clearSelection();

        SmartDialog.dismiss();
        SmartDialog.dismiss(status: SmartStatus.loading);
        showToast('删除成功');
      } else {
        SmartDialog.dismiss();
        SmartDialog.dismiss(status: SmartStatus.loading);
        showToast('删除失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast('删除失败');
      AppLogger.error('删除设计失败:', e);
    }
  }

  /// 收藏事件处理
  Future<void> clickFavorite(int itemId, bool shouldFavorite) async {
    if (global.connectStatus.currentStatus == NetworkStatus.none) {
      showToast(shouldFavorite ? "收藏失败" : "取消收藏失败");
      return;
    }

    try {
      final result = await http.post(
        shouldFavorite ? '/design/favorite-store' : '/design/favorite-destroy',
        data: {"link_id": '$itemId'},
      );

      if (result.code == 0) {
        showToast(shouldFavorite ? "收藏成功" : "取消收藏成功");

        // 更新 isFavorite 状态
        final newFavoriteStatus = shouldFavorite ? 1 : 0;

        // 更新 tabDataMap 中每个 TabDataState 的 dataList 中的 item
        for (var tabData in tabDataMap.values) {
          final dataIndex = tabData.dataList.indexWhere(
            (item) => item.id == itemId,
          );
          if (dataIndex != -1) {
            final oldItem = tabData.dataList[dataIndex];
            final favoriteTotal =
                (oldItem.favoriteTotal) + (shouldFavorite ? 1 : -1);
            tabData.dataList[dataIndex] = oldItem.copyWith(
              isFavorite: newFavoriteStatus,
              favoriteTotal: favoriteTotal,
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('收藏操作失败:', e);
    }
  }

  /// 取消收藏事件
  void favoriteEventDialog(int itemId) {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "取消收藏",
        subTitle: "是否确认取消收藏该模版",
        sureAction: () => clickFavorite(itemId, false),
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }
}
