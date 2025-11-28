import 'package:common/common.dart';
import 'resource_model.dart';

class AppResourceLogic extends GetxController {
  // 获取到参数
  String type = Get.arguments is String ? Get.arguments : null;

  /// 总空间（这里写死 512MB，可从服务端下发）
  final int totalSpaceBytes = 512 * 1024 * 1024;

  /// 已用空间
  final RxInt usedSpaceBytes = (45 * 1024 * 1024).obs;

  /// 草稿列表
  final RxList<ResourceModel> drafts = <ResourceModel>[].obs;

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
        (index) => ResourceModel(
          id: index + 1,
          title: '新文件 ${index + 1}',
          sizeBytes: 5 * 1024 * 1024, // 每个草稿 5MB
        ),
      ),
    );
    _recalcUsedSpace();
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
    selectedIds.refresh();
  }

  /// 全选
  void toggleSelectAll() {
    if (isAllSelected) {
      selectedIds.clear();
    } else {
      selectedIds
        ..clear()
        ..addAll(drafts.map((e) => e.id));
    }
    selectedIds.refresh();
  }

  /// 取消
  void clearSelection() {
    isBatchMode.value = false;
    selectedIds.clear();
    selectedIds.refresh();
  }

  /// 删除选中的草稿
  void deleteSelected() {
    if (selectedIds.isEmpty) return;
    drafts.removeWhere((e) => selectedIds.contains(e.id));
    selectedIds.clear();
    _recalcUsedSpace();
  }

  /// 删除单个草稿（非批量模式下点击删除按钮）
  void deleteOne(int id) {
    drafts.removeWhere((e) => e.id == id);
    selectedIds.remove(id);
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
