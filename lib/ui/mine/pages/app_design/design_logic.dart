import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/design_model.dart';
import 'package:voicetemplate/ui/model/index.dart';

class AppDesiginLogic extends GetxController {
  /// 头部的tab
  final screenList = <ScreenItemModel>[].obs;

  /// 图片列表
  final RxList<DesignItemModel> designList = <DesignItemModel>[].obs;

  /// 当前页码
  int currentPage = 1;

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 选中的草稿 id 集合
  final RxSet<String> selectedIds = <String>{}.obs;

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;

  /// 是否还有更多数据
  final RxBool hasMore = true.obs;

  /// 当前选中的 tab 索引
  final RxInt selectedTabIndex = 0.obs;

  // bool get isAllSelected =>
  //     drafts.isNotEmpty && selectedIds.length == drafts.length;

  /// 初始化一些假数据
  @override
  void onInit() {
    super.onInit();
    // 初始化时获取 tab 数据
    getSuggestedTags();
    loadDesignList(refresh: true);
  }

  /// 切换 tab
  void switchTab(int index) {
    if (selectedTabIndex.value == index) return;
    selectedTabIndex.value = index;
    // 切换 tab 时重新加载数据
    loadDesignList(refresh: true);
  }

  /// 风格标签
  Future<void> getSuggestedTags() async {
    try {
      final result = await http.post(
        '/tag/index',
        withToken: true,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        final model = ScreenItemModel(id: 0, name: '全部');
        listModel.items.insert(0, model);
        screenList.value = listModel.items;
      }
    } catch (e) {
      debugPrint('获取场景数据失败: $e');
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadDesignList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad() async {
    await loadDesignList(refresh: false);
  }

  /// 加载图片列表
  /// [refresh] 是否为刷新操作（重置到第一页）
  Future<void> loadDesignList({bool refresh = false}) async {
    if (isLoading.value) {
      return;
    }
    if (refresh) {
      currentPage = 1;
    }
    isLoading.value = true;
    try {
      // 获取当前选中的 tab id
      int? tagId;
      if (screenList.isNotEmpty && selectedTabIndex.value < screenList.length) {
        final selectedTab = screenList[selectedTabIndex.value];
        tagId = selectedTab.id == 0 ? null : selectedTab.id;
      }

      final query = <String, dynamic>{
        'page': '$currentPage',
        'limit': globalPageSize,
      };
      if (tagId != null) {
        query['tag_id'] = tagId;
      }

      final result = await http.get(
        '/design/index',
        query: query,
        withToken: true,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        final listModel = DesignModel.fromJson(result.data);
        if (currentPage == 1) {
          designList.clear();
        }
        if (listModel.items.isNotEmpty) {
          designList.addAll(listModel.items);
          currentPage++;
          hasMore.value = true;
        } else {
          hasMore.value = false;
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint('我的设计数据: $e');
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
    // if (isAllSelected) return;
    // selectedIds
    //   ..clear()
    //   ..addAll(drafts.map((e) => e.id));
  }

  /// 取消
  void clearSelection() {
    isBatchMode.value = false;
    selectedIds.clear();
  }

  /// 删除选中的草稿
  void deleteSelected() {
    if (selectedIds.isEmpty) return;
    // drafts.removeWhere((e) => selectedIds.contains(e.id));
    clearSelection();
  }
}
