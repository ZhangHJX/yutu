import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'middle_model.dart';
import 'package:voicetemplate/ui/widgets/index.dart';

class MiddleLogic extends GetxController {
  final args = Get.arguments as Map<String, dynamic>;
  int get itemId => args['id'] as int;
  String get type => args['type'] as String;

  final middleInfo = Rxn<MiddleModel>();

  String get imgUrl =>
      '${middleInfo.value?.originalImage}${middleInfo.value?.thumbnail}';

  int get isFavorite => middleInfo.value?.isFavorite ?? 0;

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
      final result = await http.post(
        type == "home" ? '/homePage/read' : '/homePage/search/read',
        data: {"id": itemId},
        converter: MiddleModel.fromJson,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        middleInfo.value = result.data;
      }
    } catch (e) {
      debugPrint('获取详情页数据失败: $e');
    }
  }

  /// 收藏事件处理
  Future<void> clickFavoriteEvent() async {
    try {
      final result = await http.post(
        '/user/favorite/store',
        data: {"link_id": itemId},
        showErrorToast: false,
      );
      debugPrint("===favorite===收藏事件===${result.code}===");
      if (result.code == 0 && result.data != null) {}
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
        sureAction: () {},
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
}
