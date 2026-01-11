import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'model/home_model.dart';
import '../model/index.dart';
import 'package:voicetemplate/ui/widgets/index.dart';

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

  final searchText = ''.obs;

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
  void createTabController({int initialIndex = 0}) {
    final newLength = screenList.length;
    if (newLength == 0) return;

    // 如果 TabController 已存在且长度相同，只需要更新索引
    if (tabController.value != null &&
        tabController.value!.length == newLength) {
      if (tabController.value!.index != initialIndex) {
        tabController.value!.animateTo(initialIndex);
      }
      selectedTabIndex.value = initialIndex;
      return;
    }

    // 创建新的 TabController
    final newController = TabController(
      length: newLength,
      vsync: this,
      initialIndex: initialIndex,
    );
    newController.addListener(_onTabControllerChanged);
    tabController.value = newController;
    selectedTabIndex.value = initialIndex;
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

        // 根据 isSelect 字段找到应该选中的 tab 索引
        int selectedIndex = 0;

        // 初始化每个 tag 的数据到 tabDataMap
        for (var index = 0; index < screenList.length; index++) {
          final tag = screenList[index];
          final tabData = _getOrCreateTabData(tag.id);

          if (tag.list.isNotEmpty) {
            // 如果 tag 的 list 不为空，初始化数据
            tabData.dataList.value = tag.list;
            tabData.isInitialized = true;
            tabData.currentPage = 1;
            tabData.hasMore.value = true;
          }

          // 根据后台的 isSelect 标识设置选中的 tab
          if (tag.isSelect == 1) {
            selectedIndex = index;
          }
        }

        // 设置选中的 tab 索引
        selectedTabIndex.value = selectedIndex;

        // 创建 TabController，并设置初始索引
        createTabController(initialIndex: selectedIndex);
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
  Future<void> onLoadMore({int? tagId}) async {
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
          'title': searchText.value,
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

  /// 收藏事件处理
  Future<void> clickFavorite(int itemId, bool shouldFavorite) async {
    try {
      final result = await http.post(
        shouldFavorite
            ? '/homePage/search/favorite-store'
            : '/homePage/search/favorite-destroy',
        data: {"link_id": '$itemId'},
        showErrorToast: false,
      );
      if (result.code == 0) {
        // 更新 isFavorite 状态
        final newFavoriteStatus = shouldFavorite ? 1 : 0;

        // 更新 screenList 中每个 TagModel 的 list 中的 item
        final updatedScreenList = <TagModel>[];
        for (var tag in screenList) {
          final tagIndex = tag.list.indexWhere((item) => item.id == itemId);
          if (tagIndex != -1) {
            final updatedList = List<CommonItemModel>.from(tag.list);
            final oldItem = updatedList[tagIndex];
            final favoriteTotal =
                (oldItem.favoriteTotal) + (shouldFavorite ? 1 : -1);
            updatedList[tagIndex] = oldItem.copyWith(
              isFavorite: newFavoriteStatus,
              favoriteTotal: favoriteTotal,
            );
            updatedScreenList.add(tag.copyWith(list: updatedList));
          } else {
            updatedScreenList.add(tag);
          }
        }
        if (updatedScreenList.isNotEmpty) {
          screenList.value = updatedScreenList;
        }

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
      debugPrint('获取详情页数据失败: $e');
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
