import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'model/middle_model.dart';
import 'package:voicetemplate/ui/widgets/index.dart';

class MiddleLogic extends GetxController {
  final args = Get.arguments as Map<String, dynamic>;
  int get itemId => args['id'] as int;
  PageSource get type => args['type'] as PageSource;

  final middleInfo = Rxn<MiddleModel>();

  String get imgUrl =>
      '${middleInfo.value?.originalImage}${middleInfo.value?.thumbnail}';

  final isFavorite = 0.obs;

  List<TagItemModel> get tagArray => middleInfo.value?.tagData ?? [];

  @override
  void onInit() {
    super.onInit();
    getMidelDetailData();
  }

  /// 加载中间页的页面
  Future<void> getMidelDetailData() async {
    await getMiddleData();
  }

  Future<void> getMiddleData() async {
    try {
      debugPrint("==getMiddleData==${getMiddleUrlPath(type)}=======");

      final result = await http.post(
        getMiddleUrlPath(type),
        data: {"id": itemId},
        converter: MiddleModel.fromJson,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        middleInfo.value = result.data;
        isFavorite.value = result.data!.isFavorite;
      }
    } catch (e) {
      debugPrint('获取详情页数据失败: $e');
    }
  }

  String getMiddleUrlPath(PageSource source) {
    if (source == PageSource.home) {
      return '/homePage/read';
    } else {
      return '/homePage/search/read';
    }
  }

  /// 收藏事件处理
  Future<void> clickFavoriteEvent(bool shouldFavorite) async {
    try {
      final result = await http.post(
        getFavoriteUrlPath(type, shouldFavorite),
        data: {"link_id": itemId},
        showErrorToast: false,
      );
      debugPrint("===favorite===收藏事件===${result.code}===");
      if (result.code == 0) {
        // 更新 isFavorite 状态
        isFavorite.value = shouldFavorite ? 1 : 0;
        // 同步更新 middleInfo 中的 isFavorite
        if (middleInfo.value != null) {
          middleInfo.value!.isFavorite = isFavorite.value;
        }
      }
    } catch (e) {
      debugPrint('获取详情页数据失败: $e');
    }
  }

  /// 取消收藏事件
  void favoriteEventDialog() {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "取消收藏",
        subTitle: "是否确认取消收藏该模版",
        sureAction: () => clickFavoriteEvent(false),
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

  String getFavoriteUrlPath(PageSource source, bool isFavorite) {
    if (source == PageSource.home) {
      return isFavorite
          ? '/homePage/favorite-store'
          : '/homePage/favorite-destroy';
    } else {
      return isFavorite
          ? '/homePage/search/favorite-store'
          : '/homePage/search/favorite-destroy';
    }
  }
}
