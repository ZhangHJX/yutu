import 'package:common/common.dart';
import 'common_model.dart';

class TabDataState {
  /// 图片列表
  final RxList<CommonItemModel> designList = <CommonItemModel>[].obs;

  /// 当前页码
  int currentPage = 1;

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 是否还有更多数据
  final RxBool hasMore = true.obs;

  /// 是否已初始化（用于懒加载）
  bool isInitialized = false;
}
