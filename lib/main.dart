import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import './core/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 日志打印系统
  await AppLogger.instance.init();

  // 显示状态栏 + 底部导航栏（如果你也隐藏了的话）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 状态栏透明
    ),
  );

  // 设置多语言
  Intl.defaultLocale = 'zh_CN';
  await initializeDateFormatting('zh_CN');

  // 初始化应用
  await _initializeApp();

  // 设置错误处理，避免显示异常界面
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter Error: ${details.exception}');
    }
  };

  // 运行应用
  runApp(const MyApp());
}

/// 初始化应用配置
Future<void> _initializeApp() async {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  const envFileName = String.fromEnvironment(
    'ENV_FILE',
    defaultValue: '.env.prod',
  );

  // 初始化 GetStorage
  await GetStorage.init();

  // 加载环境变量
  await dotenv.load(fileName: 'env/$envFileName');
  final dstMap = Map.fromEntries(dotenv.env.entries);

  AppLogger.info('App启动环境 $envFileName  $dstMap');
  await dotenv.load(fileName: 'env/.env', mergeWith: dstMap);

  final cost = DateTime.now().millisecondsSinceEpoch - startTime;
  AppLogger.info('App启动耗时 多长时间 $cost ms');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      child: RefreshConfiguration(
        footerTriggerDistance: 15,
        headerBuilder: () => ClassicHeader(),
        footerBuilder: () => ClassicFooter(),
        springDescription: SpringDescription(
          mass: 1,
          stiffness: 100,
          damping: 20,
        ),
        maxOverScrollExtent: 100,
        maxUnderScrollExtent: 0,
        enableScrollWhenRefreshCompleted: true,
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
          initialRoute: AppRoutes.main,
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
