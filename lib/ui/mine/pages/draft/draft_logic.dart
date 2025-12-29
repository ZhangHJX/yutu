import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'draft_model.dart';

class DraftLogic extends GetxController {
  /// 是否正在请求数据
  final RxBool isLoading = false.obs;

  /// 当前页码
  int currentPage = 1;

  /// 总空间（这里写死 512MB，可从服务端下发）
  final int totalSpaceBytes = 512 * 1024 * 1024;

  /// 已用空间
  final RxInt usedSpaceBytes = (45 * 1024 * 1024).obs;

  /// 草稿列表
  final RxList<DraftModel> drafts = <DraftModel>[].obs;

  /// 选中的草稿 id 集合
  final RxSet<int> selectedIds = <int>{}.obs;

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;

  int get selectedCount => selectedIds.length;

  bool get isAllSelected =>
      drafts.isNotEmpty && selectedIds.length == drafts.length;

  double get usedRatio =>
      totalSpaceBytes == 0 ? 0 : usedSpaceBytes.value / totalSpaceBytes;

  /// 初始化一些假数据
  @override
  void onInit() {
    super.onInit();
    drafts.addAll(
      List.generate(
        6,
        (index) => DraftModel(
          id: index + 1,
          title: '新文件 ${index + 1}',
          sizeBytes: 5 * 1024 * 1024, // 每个草稿 5MB
        ),
      ),
    );
    _recalcUsedSpace();
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadDataList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad({int? tagId}) async {
    await loadDataList(refresh: false);
  }

  /// 加载图片列表
  Future<void> loadDataList({bool refresh = false}) async {
    if (isLoading.value) {
      return;
    }
    if (refresh) {
      currentPage = 1;
    }
    isLoading.value = true;
    try {
      final result = await http.get(
        '/design/draft/index',
        query: {'page': '$currentPage', 'limit': globalPageSize},
        showErrorToast: false,
      );

      // if (result.code == 0 && result.data != null) {
      //   final listModel = DesignModel.fromJson(result.data);
      //   if (tabData.currentPage == 1) {
      //     tabData.designList.clear();
      //   }
      //   if (listModel.items.isNotEmpty) {
      //     tabData.designList.addAll(listModel.items);
      //     tabData.currentPage++;
      //     tabData.hasMore.value = true;
      //   } else {
      //     tabData.hasMore.value = false;
      //   }
      //   tabData.isInitialized = true;
      // }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint('草稿列表数据请求错误: $e');
    }
  }

  void _recalcUsedSpace() {
    usedSpaceBytes.value = drafts.fold(0, (prev, e) => prev + e.sizeBytes);
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
    debugPrint("---deleteSelected-111-");
    if (selectedIds.isEmpty) return;
    drafts.removeWhere((e) => selectedIds.contains(e.id));
    debugPrint("---deleteSelected-222-");
    clearSelection();
    _recalcUsedSpace();
  }

  String formatMB(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 100) {
      return mb.toStringAsFixed(0);
    }
    return mb.toStringAsFixed(1);
  }
}
