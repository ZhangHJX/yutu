import 'package:common/common.dart';
import 'app_route_const.dart';

import 'package:voicetemplate/ui/not_found_page.dart';
import 'package:voicetemplate/ui/splash/page.dart';
import 'package:voicetemplate/app/main/page.dart';
import 'package:voicetemplate/ui/canvas/pages/canvals/canvals_editor_page.dart';
import 'package:voicetemplate/ui/login/login_page.dart';
import 'package:voicetemplate/ui/login/password/password_page.dart';

/// 搜索页面
import 'package:voicetemplate/ui/home/search_page.dart';
import 'package:voicetemplate/ui/middle/middle_page.dart';

/// 我的模块
import 'package:voicetemplate/ui/mine/pages/person_info/person_info_page.dart';
import 'package:voicetemplate/ui/mine/pages/info/app_info_page.dart';
import 'package:voicetemplate/ui/mine/pages/stock/stock_page.dart';
import 'package:voicetemplate/ui/mine/pages/draft/draft_page.dart';
import 'package:voicetemplate/ui/mine/pages/design/app_design_page.dart';
import 'package:voicetemplate/ui/mine/pages/collection/app_collection_page.dart';
import 'package:voicetemplate/common/web/page.dart';

final List<GetPage> getPages = [
  /// 启动页
  GetPage(name: AppRoutes.splash, page: SplashPage.new),

  /// 登录页
  GetPage(
    name: AppRoutes.appLogin,
    page: LoginPage.new,
    transition: Transition.downToUp,
  ),
  GetPage(name: AppRoutes.password, page: PasswordPage.new),

  /// TabBar
  GetPage(
    name: AppRoutes.main,
    page: MainPage.new,
    transition: Transition.fadeIn,
  ),

  /// 搜索页面
  GetPage(name: AppRoutes.search, page: SearchPage.new),
  GetPage(name: AppRoutes.middle, page: MiddlePage.new),

  // 创建设计页面
  // GetPage(name: AppRoutes.designPage, page: CreateDesignPage.new, transition: Transition.downToUp),

  // 画布页面
  GetPage(name: AppRoutes.canvalsPage, page: CanvasEditorPage.new),

  //我的模块
  GetPage(name: AppRoutes.appInfoPage, page: AppInfoPage.new),
  GetPage(name: AppRoutes.personInfo, page: PersonInfoPage.new),

  GetPage(name: AppRoutes.draft, page: AppDraftPage.new),
  GetPage(name: AppRoutes.stock, page: AppStockPage.new),
  GetPage(name: AppRoutes.design, page: AppDesignPage.new),
  GetPage(name: AppRoutes.collection, page: AppCollectionPage.new),

  GetPage(name: AppRoutes.web, page: WebPage.new),
];

final unknownRoute = GetPage(name: AppRoutes.notFound, page: NotFoundPage.new);
