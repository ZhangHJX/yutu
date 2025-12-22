import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'image_model.dart';

class ImageLogic extends GetxController {
  // 图片列表
  final RxList<ImageModel> imageList = <ImageModel>[].obs;

  // 当前页码
  int currentPage = 1;

  // 每页数量
  final int pageSize = 20;

  // 是否还有更多数据
  bool hasMore = true;

  // 是否正在加载
  final RxBool isLoading = false.obs;

  // 是否正在刷新
  final RxBool isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化时加载第一页数据
    loadImageList(refresh: true);
  }

  /// 加载图片列表
  /// [refresh] 是否为刷新操作（重置到第一页）
  Future<void> loadImageList({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      hasMore = true;
      isRefreshing.value = true;
    } else {
      if (!hasMore || isLoading.value) {
        return;
      }
      isLoading.value = true;
    }

    try {
      final result = await http.post(
        '/your/image/list/endpoint', // 替换为实际的接口地址
        withToken: true,
        showErrorToast: false,
        data: {'pageNum': currentPage, 'pageSize': pageSize},
        converter: pageConverter<ImageModel>(
          (json) => ImageModel.fromJson(json),
        ),
      );

      if (result.code == 0 && result.data != null) {
        final pageData = result.data!;

        if (refresh) {
          imageList.clear();
        }

        imageList.addAll(pageData.list);

        // 判断是否还有更多数据
        hasMore = !pageData.isLastPage;

        if (hasMore) {
          currentPage++;
        }
      }
    } catch (e) {
      debugPrint('加载图片列表失败: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadImageList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad() async {
    await loadImageList(refresh: false);
  }
}
