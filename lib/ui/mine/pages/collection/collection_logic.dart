import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/common_model.dart';
import 'package:voicetemplate/ui/model/index.dart';
import '../../../model/tab_data_state.dart';

class CollectionLogic extends GetxController with GetTickerProviderStateMixin {
  /// 头部的tab
  final screenList = <ScreenItemModel>[].obs;
  // 当前选中的 tab 索引
  final RxInt selectedTabIndex = 0.obs;
  // 每个 tab 的数据状态（使用 tagId 作为 key，0 表示全部）
  final Map<int, TabDataState> tabDataMap = {};

  /// TabController
  final Rxn<TabController> tabController = Rxn<TabController>();

  /// 选中的草稿 id 集合
  final RxSet<String> selectedIds = <String>{}.obs;

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;
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

  bool get isAllSelected {
    final list = designList;
    return list.isNotEmpty && selectedIds.length == list.length;
  }

  GlobalKey refresherKey = GlobalKey();
  RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

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
    refreshController.dispose();
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
      final result = await http.post('/tag/index', showErrorToast: false);
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
      debugPrint('获取场景数据失败: $e');
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
        '/user/favorite/index',
        query: {
          'page': '${tabData.currentPage}',
          'limit': globalPageSize,
          'tag_id': targetTagId,
        },
        showErrorToast: false,
      );

      if (result.code == 0 && result.data != null) {
        final listModel = CommonModel.fromJson(result.data);
        if (tabData.currentPage == 1) {
          tabData.dataList.clear();
        }
        if (listModel.items.isNotEmpty) {
          tabData.dataList.addAll(listModel.items);
          tabData.currentPage++;
          tabData.hasMore.value = true;
        } else {
          tabData.hasMore.value = false;
        }
        tabData.isInitialized = true;
      }
      // 更新刷新控制器状态
      if (refresh) {
        refreshController.refreshCompleted();
      } else {
        if (hasMore.value) {
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }
      tabData.isLoading.value = false;
    } catch (e) {
      tabData.isLoading.value = false;
      debugPrint('列表数据请求错误: $e');
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
  void toggleItemSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  /// 全选
  void toggleSelectAll() {
    final list = designList;
    if (list.isEmpty) return;
    if (isAllSelected) {
      // 如果已全选，则取消全选
      selectedIds.clear();
    } else {
      // 否则全选当前tab的所有项
      selectedIds.clear();
      selectedIds.addAll(list.map((e) => '${e.id}').toList());
    }
  }

  /// 取消
  void clearSelection() {
    isBatchMode.value = false;
    selectedIds.clear();
  }

  /// 删除选中的设计
  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;
    try {
      // 发送删除请求，将选中的uuid列表作为参数
      final result = await http.post(
        '/user/favorite/destroys',
        data: {'ids': selectedIds.toList().join(',')},
        showErrorToast: true,
      );

      if (result.code == 0) {
        // 删除成功，从当前tab的数据列表中移除已删除的项
        final tagId = _getCurrentTagId();
        final tabData = tabDataMap[tagId];
        if (tabData != null) {
          tabData.dataList.removeWhere(
            (item) => selectedIds.contains('${item.id}'),
          );
        }
        // 清除选择并退出批量模式
        clearSelection();
      }
    } catch (e) {
      debugPrint('删除设计失败: $e');
    }
  }
}
