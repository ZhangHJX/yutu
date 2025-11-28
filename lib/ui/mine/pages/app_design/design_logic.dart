import 'package:common/common.dart';
import 'desigin_model.dart';

class AppDesiginLogic extends GetxController {
  /// 草稿列表
  final RxList<DesiginModel> drafts = <DesiginModel>[].obs;

  /// 选中的草稿 id 集合
  final RxSet<int> selectedIds = <int>{}.obs;

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;

  bool get isAllSelected =>
      drafts.isNotEmpty && selectedIds.length == drafts.length;

  /// 初始化一些假数据
  @override
  void onInit() {
    super.onInit();
    drafts.addAll(
      List.generate(
        6,
        (index) => DesiginModel(
          id: index + 1,
          title: '新文件 ${index + 1}',
          likeCount: 100,
        ),
      ),
    );
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
    if (isAllSelected) return;
    selectedIds
      ..clear()
      ..addAll(drafts.map((e) => e.id));
  }

  /// 取消
  void clearSelection() {
    isBatchMode.value = false;
    selectedIds.clear();
  }

  /// 删除选中的草稿
  void deleteSelected() {
    if (selectedIds.isEmpty) return;
    drafts.removeWhere((e) => selectedIds.contains(e.id));
    clearSelection();
  }
}
