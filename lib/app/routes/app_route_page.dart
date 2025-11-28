import 'package:common/common.dart';
import 'app_route_const.dart';

import 'package:voicetemplate/ui/not_found_page.dart';
import 'package:voicetemplate/ui/splash/page.dart';
import 'package:voicetemplate/ui/main/page.dart';
import 'package:voicetemplate/ui/canvas/controllers/canvals_editor_page.dart';

/// 我的模块
import 'package:voicetemplate/ui/mine/pages/app_info/app_info_page.dart';
import 'package:voicetemplate/ui/mine/pages/resource/resource_page.dart';

final List<GetPage> getPages = [
  /// 启动页
  GetPage(name: AppRoutes.splash, page: SplashPage.new),

  /// TabBar
  GetPage(
    name: AppRoutes.main,
    page: MainPage.new,
    transition: Transition.fadeIn,
  ),

  // 创建设计页面
  // GetPage(name: AppRoutes.designPage, page: CreateDesignPage.new, transition: Transition.downToUp),

  // 画布页面
  GetPage(name: AppRoutes.createCanvalsPage, page: CanvasEditorPage.new),

  //我的模块
  GetPage(name: AppRoutes.appInfoPage, page: AppInfoPage.new),
  GetPage(name: AppRoutes.resourcePage, page: AppResourcePage.new),
];

final unknownRoute = GetPage(name: AppRoutes.notFound, page: NotFoundPage.new);
