import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'model/home_model.dart';
import '../model/index.dart';

class SearchLogic extends GetxController with GetTickerProviderStateMixin {
  /// 顶部tab数据
  final RxBool tabIsLoading = false.obs;

  /// 头部的tab
  final screenList = <TagModel>[].obs;

  /// TabController
  final Rxn<TabController> tabController = Rxn<TabController>();

  // 当前选中的 tab 索引
  final RxInt selectedTabIndex = 0.obs;

  // 每个 tab 的数据状态（使用 tagId 作为 key，0 表示全部）
  final Map<int, TabDataState> tabDataMap = {};

  /// 获取当前 tab 是否还有更多数据
  RxBool get hasMore {
    final tagId = _getCurrentTagId();
    return tabDataMap[tagId]?.hasMore ?? true.obs;
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

  @override
  void onInit() {
    super.onInit();
    getTabTags();
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
          loadSearchList(refresh: true);
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
      loadSearchList(refresh: true);
    }
  }

  /// 风格标签
  Future<void> getTabTags() async {
    try {
      tabIsLoading.value = true;
      final result = await http.get(
        '/homePage/search/index',
        query: {'page': '1', 'limit': globalPageSize},
        showErrorToast: false,
        converter: HomeModel.fromJson,
      );
      if (result.code == 0 && result.data != null) {
        screenList.value = result.data!.tagList;

        // 初始化每个 tag 的数据到 tabDataMap
        for (var index = 0; index < screenList.length; index++) {
          final tag = screenList[index];
          final tabData = _getOrCreateTabData(tag.id);
          if (tag.list.isNotEmpty) {
            // 如果 tag 的 list 不为空，初始化数据
            selectedTabIndex.value = index;
            tabData.dataList.value = tag.list;
            tabData.isInitialized = true;
            tabData.currentPage = 1;
            tabData.hasMore.value = true;
          }
        }
        // 创建 TabController
        createTabController();
      }
      tabIsLoading.value = false;
    } catch (e) {
      tabIsLoading.value = false;
      debugPrint('获取场景数据失败: $e');
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadSearchList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad({int? tagId}) async {
    await loadSearchList(refresh: false);
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
  Future<void> loadSearchList({bool refresh = false}) async {
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
        '/homePage/search/where-index',
        query: {
          'page': '${tabData.currentPage}',
          'limit': globalPageSize,
          'title': '',
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
      // 更新刷新控制器状态 - 使用当前 tab 的 refreshController
      if (refresh) {
        tabData.refreshController.refreshCompleted();
      } else {
        if (hasMore.value) {
          tabData.refreshController.loadComplete();
        } else {
          tabData.refreshController.loadNoData();
        }
      }
      tabData.isLoading.value = false;
    } catch (e) {
      tabData.isLoading.value = false;
      debugPrint('列表数据请求错误: $e');
      // 处理错误状态 - 使用当前 tab 的 refreshController
      if (refresh) {
        tabData.refreshController.refreshFailed();
      } else {
        tabData.refreshController.loadFailed();
      }
    }
  }
}
