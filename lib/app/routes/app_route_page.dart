import 'package:common/common.dart';
import 'app_route_const.dart';

import 'package:voicetemplate/ui/not_found_page.dart';
import 'package:voicetemplate/ui/splash/page.dart';
import 'package:voicetemplate/ui/main/page.dart';
import 'package:voicetemplate/ui/canvas/create_canvals_page.dart';

final List<GetPage> getPages = [
  /// 启动页
  GetPage(name: AppRoutes.splash, page: SplashPage.new),

  /// TabBar
  GetPage(
    name: AppRoutes.main,
    page: MainPage.new,
    transition: Transition.fadeIn,
  ),

  // 画布页面
  GetPage(name: AppRoutes.createCanvalsPage, page: CreateCanvalsPage.new),
];

final unknownRoute = GetPage(name: AppRoutes.notFound, page: NotFoundPage.new);
