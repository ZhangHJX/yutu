import 'package:common/common.dart';
import 'package:voicetemplate/pages/model/index.dart';

class HomeTabDataState {
  /// 图片列表
  RxList<CommonItemModel> dataList = <CommonItemModel>[].obs;

  /// 当前页码
  int currentPage = 1;

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 是否还有更多数据
  final RxBool hasMore = true.obs;

  /// 是否已初始化（用于懒加载）
  bool isInitialized = false;
}
