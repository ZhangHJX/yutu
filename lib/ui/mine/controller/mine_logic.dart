import 'package:common/common.dart';
import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../../../app/routes/index.dart';

const _mockAvatar =
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80';

const List<String> _mockDesignImages = [
  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
  'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=400&q=80',
  'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=400&q=80',
  'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=400&q=80',
  'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=400&q=80',
  'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=400&q=80',
  'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=400&q=80',
];

class MineLogic extends GetxController {
  final userInfo = UserModel().obs;
  final isLogin = true.obs;

  @override
  void onInit() {
    super.onInit();
  }

  /// 模拟登录
  void login() {
    isLogin.value = true;
    userInfo.value
      ..isLogin = true
      ..avatar = _mockAvatar
      ..nickname = '设计达人'
      ..workCount = 8
      ..designImages = [..._mockDesignImages];
  }

  /// 退出登录
  void logout() {
    userInfo.value = UserModel();
    isLogin.value = false;
  }

  /// 我的主页面点击事件
  void onTapMyServices() => isLogin.value = !isLogin.value;
  void onTapPersonInfo() => Get.toNamed(AppRoutes.personInfo);

  void onTapMyDesign() =>
      Get.toNamed(AppRoutes.designPage, arguments: userInfo.value);

  /// 常用工具事件
  void onTapMyDraft() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "draft");
  void onTapMyFavorite() => _showComingSoon('我的收藏');
  void onTapMyResource() =>
      Get.toNamed(AppRoutes.resourcePage, arguments: "resource");

  void onTapService() => _showComingSoon('我的客服');

  void goToAppInfo() => Get.toNamed(AppRoutes.appInfoPage);

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
