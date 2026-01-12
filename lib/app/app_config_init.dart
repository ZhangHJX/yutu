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
      child: RefreshConfiguration(
        footerTriggerDistance: 15,
        headerBuilder: () => const ClassicHeader(),
        footerBuilder: () => const ClassicFooter(),
        hideFooterWhenNotFull: true,
        enableLoadingWhenNoData: false,
        child: GetMaterialApp(
          unknownRoute: unknownRoute,
          title: '语图',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.lightTheme(),
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            RefreshLocalizations.delegate,
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
      ),
    );
  }
}
