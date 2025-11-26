import 'package:common/common.dart';
import 'package:flutter/material.dart';

import '../model/mine_info_model.dart';

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

class MineController extends GetxController {
  final state = MineInfoModel();
  final isLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    _mockInit();
  }

  void _mockInit() {
    isLogin.value = false;
    state
      ..isLogin = false
      ..avatar = ''
      ..nickname = ''
      ..workCount = 0
      ..designImages = [..._mockDesignImages];
  }

  /// 模拟登录
  void login() {
    isLogin.value = true;
    state
      ..isLogin = true
      ..avatar = _mockAvatar
      ..nickname = '设计达人'
      ..workCount = 8
      ..designImages = [..._mockDesignImages];
  }

  /// 退出登录
  void logout() {
    _mockInit();
  }

  void onTapMyServices() => _showComingSoon('我的客服');

  void onTapMyDesign() => _showComingSoon('我的设计');

  void onTapMyDraft() => _showComingSoon('我的草稿');

  void onTapMyFavorite() => _showComingSoon('我的收藏');

  void onTapMyAssets() => _showComingSoon('我的素材');

  void onTapService() => _showComingSoon('我的客服');

  void onTapSoftwareInfo() => _showComingSoon('软件信息');

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
