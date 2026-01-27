import 'package:common/common.dart';
import '../../model/stock_model.dart';
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/stores/user_model.dart';
import 'package:voicetemplate/core/index.dart';

class StockLogic extends GetxController {
  /// 全局
  final global = Get.find<GlobalLogic>();

  /// 是否正在请求数据
  final RxBool isLoading = false.obs;

  /// 当前页码
  int currentPage = 1;

  /// 列表数据
  final stockList = <StockItemModel>[].obs;

  /// 是否还有数据
  final RxBool hasMore = true.obs;

  /// 选中的草稿 id 集合
  final RxSet<String> selectedIds = <String>{}.obs;

  /// 是否处于批量模式
  final RxBool isBatchMode = false.obs;

  int get selectedCount => selectedIds.length;

  /// 是否全选
  bool get isAllSelected =>
      stockList.isNotEmpty && selectedIds.length == stockList.length;

  Worker? _countWorker;

  final userInfo = UserModel().obs;

  @override
  void onClose() {
    _countWorker?.dispose();
    super.onClose();
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
    refreshUserInfo();

    _countWorker = ever(global.userInfo, (user) {
      userInfo.value = user;
    });
  }

  Future<void> refreshUserInfo() async {
    await global.fetchUserInfo();
  }

  /// 加载图片列表
  Future<void> loadDataList({bool refresh = false}) async {
    if (isLoading.value) return;
    if (!hasMore.value && !refresh) return;
    if (refresh) {
      currentPage = 1;
    }
    isLoading.value = true;
    try {
      final result = await http.get(
        '/user/material/index',
        query: {'page': '$currentPage', 'limit': globalPageSize},
      );
      if (result.code == 0 && result.data != null) {
        final listModel = StockModel.fromJson(result.data);
        if (refresh) {
          stockList.clear();
        }
        if (listModel.items.isNotEmpty) {
          stockList.addAll(listModel.items);
          currentPage++;
          hasMore.value = true;
        } else {
          hasMore.value = false;
        }
      }
    } catch (e) {
      AppLogger.error('素材列表数据请求错误:', e);
    } finally {
      isLoading.value = false;
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
    if (isAllSelected) return;
    selectedIds
      ..clear()
      ..addAll(stockList.map((e) => '${e.id}'));
  }

  /// 取消
  void clearSelection() {
    isBatchMode.value = false;
    selectedIds.clear();
  }

  /// 删除选中的草稿
  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    if (global.connectStatus.currentStatus == NetworkStatus.none) {
      showToast("删除失败");
      return;
    }

    try {
      showLoading("删除中");
      // 发送删除请求，将选中的uuid列表作为参数
      final result = await http.post(
        '/user/material/destroys',
        data: {'ids': selectedIds.toList().join(',')},
      );
      if (result.code == 0) {
        // 删除成功，从当前tab的数据列表中移除已删除的项
        stockList.removeWhere((e) => selectedIds.contains('${e.id}'));
        // 清除选择并退出批量模式
        clearSelection();
        refreshUserInfo();
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
      AppLogger.error('删除设计失败: ', e);
    }
  }
}
