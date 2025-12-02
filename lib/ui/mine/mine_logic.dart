import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../stores/user_model.dart';
import '../../app/routes/index.dart';
import '../../stores/global.dart';

class MineLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  final isLogin = true.obs;

  @override
  void onInit() {
    super.onInit();
  }

  /// 点击登陆事件
  void login() => Get.toNamed(AppRoutes.appLogin);

  /// 我的主页面点击事件
  void onTapMyServices() => isLogin.value = !isLogin.value;
  void onTapPersonInfo() => Get.toNamed(AppRoutes.personInfo);

  void onTapMyDesign() =>
      Get.toNamed(AppRoutes.designPage, arguments: global.userInfo.value);

  /// 常用工具事件
  void onTapMyDraft() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "draft");
  void onTapMyFavorite() => _showComingSoon('我的收藏');
  void onTapMyResource() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "resource");

  void onTapService() => _showComingSoon('我的客服');

  void goToAppInfo() => Get.toNamed(AppRoutes.appInfoPage);

  /// 退出登录
  void logout() {
    global.userInfo.value = UserModel();
    isLogin.value = false;
  }

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
