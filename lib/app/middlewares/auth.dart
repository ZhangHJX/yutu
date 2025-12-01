import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../routes/index.dart';
import '../../stores/global.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final globalLogic = Get.find<GlobalLogic>();
    if (globalLogic.isLogin) {
      return super.redirect(route);
    } else {
      return const RouteSettings(name: AppRoutes.login);
    }
  }
}
