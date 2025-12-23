import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../app/routes/index.dart';
import '../../stores/global.dart';

class MineLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

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

  void onTapMyDesign() => Get.toNamed(AppRoutes.designPage);

  /// 常用工具事件
  void onTapMyDraft() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "draft");
  void onTapMyFavorite() => _showComingSoon('我的收藏');
  void onTapMyResource() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "resource");

  void onTapService() => _showComingSoon('我的客服');

  void goToAppInfo() => Get.toNamed(AppRoutes.appInfoPage);

  void onTapPassWord() => Get.toNamed(AppRoutes.password, arguments: false);

  /// 退出登录
  void logout() => global.logout();

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
