import 'package:common/common.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes/index.dart';
import 'binding/app_binding.dart';

class AppConfigInit extends StatelessWidget {
  const AppConfigInit({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      child: GetMaterialApp(
        unknownRoute: unknownRoute,
        title: Global.appName,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        popGesture: true,
        getPages: getPages,
        initialRoute: AppRoutes.splash,
        debugShowCheckedModeBanner: false,
        defaultTransition: Transition.rightToLeft,
        initialBinding: AppBinding(),
        navigatorObservers: [
          FlutterSmartDialog.observer,
          GetXRouteObserver(),
          SwipeActionNavigatorObserver(),
        ],
        builder: FlutterSmartDialog.init(),
      ),
    );
  }
}
