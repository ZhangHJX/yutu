import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/common_model.dart';

class DraftLogic extends GetxController {
  /// 是否正在请求数据
  final RxBool isLoading = false.obs;

  /// 当前页码
  int currentPage = 1;

  /// 列表数据
  final draftList = <CommonItemModel>[].obs;

  /// 是否还有数据
  final RxBool hasMore = true.obs;

  /// 总空间（这里写死 512MB，可从服务端下发）
  final int totalSpaceBytes = 512 * 1024 * 1024;

  /// 已用空间
  final RxInt usedSpaceBytes = (45 * 1024 * 1024).obs;

  /// 草稿列表
  // final RxList<DraftModel> drafts = <DraftModel>[].obs;

  /// 选中的草稿 id 集合
  final RxSet<String> selectedIds = <String>{}.obs;

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;

  int get selectedCount => selectedIds.length;

  /// 是否全选
  bool get isAllSelected =>
      draftList.isNotEmpty && selectedIds.length == draftList.length;

  double get usedRatio =>
      totalSpaceBytes == 0 ? 0 : usedSpaceBytes.value / totalSpaceBytes;

  /// 初始化一些假数据
  @override
  void onInit() {
    super.onInit();
    // _recalcUsedSpace();
    loadDataList();
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

      if (result.code == 0 && result.data != null) {
        final listModel = CommonModel.fromJson(result.data);
        if (currentPage == 1) {
          draftList.clear();
        }
        if (listModel.items.isNotEmpty) {
          draftList.addAll(listModel.items);
          currentPage++;
          hasMore.value = true;
        } else {
          hasMore.value = false;
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint('草稿列表数据请求错误: $e');
    }
  }

  void _recalcUsedSpace() {
    // usedSpaceBytes.value = draftList.fold(0, (prev, e) => prev + e.sizeBytes);
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
    if (isAllSelected) return;
    selectedIds
      ..clear()
      ..addAll(draftList.map((e) => '${e.id}'));
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
    draftList.removeWhere((e) => selectedIds.contains('${e.id}'));
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
