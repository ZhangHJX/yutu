import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/core/index.dart';
import '../../stores/global.dart';
import '../model/common_model.dart';
import 'dart:async';
import '../utils/app_info/app_info_utils.dart';

class MineLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  // 图片列表
  RxList<CommonItemModel> designList = <CommonItemModel>[].obs;

  late final StreamSubscription _sub;

  Worker? _countWorker;

  RxString version = '1.0.0'.obs;

  @override
  void onClose() {
    super.onClose();
    _sub.cancel();
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
    _sub = EventBusManager.share.listenAll((e) {
      debugPrint('EventBusManager 我进来了');
      if (e.type == AppEventType.mineRefresh) {
        updatePersonInfo();
      }
    });

    getCurrentAppVersion();
  }

  void getCurrentAppVersion() async {
    version.value = await AppInfoUtils.getAppVersion();
  }

  /// 加载图片列表
  Future<void> loadDesignList({bool refresh = false}) async {
    if (!global.isLogin) {
      return;
    }

    try {
      final result = await http.get(
        '/design/index',
        query: {'page': 1, 'limit': globalPageSize},
        showErrorToast: false,
      );

      if (result.code == 0 && result.data != null) {
        if (designList.isNotEmpty) {
          designList.clear();
        }
        final listModel = CommonModel.fromJson(result.data);
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
    if (!global.isLogin) return;
    Get.toNamed(AppRoutes.personInfo);
  }

  ///我的设计
  void onTapMyDesign() {
    Get.toNamed(AppRoutes.design);
  }

  ///我的草稿
  void onTapMyDraft() => Get.toNamed(AppRoutes.draft);

  ///我的收藏
  void onTapMyFavorite() => Get.toNamed(AppRoutes.collection);

  ///我的素材
  void onTapMyResource() => Get.toNamed(AppRoutes.stock);

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

  Future<void> updatePersonInfo() async {
    // 调接口刷新
    await global.fetchUserInfo();
    loadDesignList();
  }
}
