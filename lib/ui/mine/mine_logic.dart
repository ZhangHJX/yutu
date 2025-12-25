import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../app/routes/index.dart';
import '../../stores/global.dart';
import './model/design_model.dart';

class MineLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  // 图片列表
  RxList<DesignItemModel> designList = <DesignItemModel>[].obs;

  Worker? _countWorker;

  @override
  void onClose() {
    super.onClose();
    _countWorker?.dispose();
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化时加载第一页数据
    loadDesignList();
    _countWorker = ever(global.accessToken, (token) {
      loadDesignList();
    });
  }

  /// 加载图片列表
  /// [refresh] 是否为刷新操作（重置到第一页）
  Future<void> loadDesignList({bool refresh = false}) async {
    try {
      final result = await http.get(
        '/design/index',
        query: {'page': 1, 'limit': globalPageSize},
        withToken: true,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        final listModel = DesignModel.fromJson(result.data);
        if (listModel.items.isNotEmpty) {
          designList.addAll(listModel.items);
        }
      }
    } catch (e) {
      debugPrint('加载设计列表数据失败: $e');
    }
  }

  /// 点击登陆事件
  void login() {
    if (global.isLogin) return;
    Get.toNamed(AppRoutes.appLogin);
  }

  /// 个人资料
  void onTapPersonInfo() {
    global.removeUserInfo();
    if (!global.isLogin) return;
    Get.toNamed(AppRoutes.personInfo);
  }

  ///我的设计
  void onTapMyDesign() => Get.toNamed(AppRoutes.designPage);

  ///我的草稿
  void onTapMyDraft() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "draft");

  ///我的收藏
  void onTapMyFavorite() => _showComingSoon('我的收藏');

  ///我的素材
  void onTapMyResource() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "resource");

  ///我的客服
  void onTapService() => _showComingSoon('我的客服');

  ///设置密码
  void onTapPassWord() => Get.toNamed(AppRoutes.password, arguments: false);

  ///软件信息
  void goToAppInfo() => Get.toNamed(AppRoutes.appInfoPage);

  /// 退出登录
  void logout() => global.logout();

  /// 常用工具事件
  void _showComingSoon(String title) {
    Get.snackbar(
      '提示',
      '$title 功能敬请期待',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1100),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
