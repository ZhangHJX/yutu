import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import './core/index.dart';

void main() async {
  // 记录应用启动开始时间（从 Flutter 绑定初始化开始）
  final appStartTime = DateTime.now().millisecondsSinceEpoch;

  WidgetsFlutterBinding.ensureInitialized();

  // 异步初始化日志系统（不阻塞启动流程）
  AppLogger.instance.init().catchError((e) {
    if (kDebugMode) {
      debugPrint('日志系统初始化失败: $e');
    }
  });

  // 初始化应用核心配置（包含在启动时间测试中）
  await _initializeApp(appStartTime);

  // 设置错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter Error: ${details.exception}');
    }
  };

  // 运行应用
  runApp(const MyApp());

  // 应用启动后，异步执行非关键初始化（不阻塞 UI 渲染）
  _initializeNonCritical();
}

/// 初始化应用核心配置（关键路径，影响启动时间）
Future<void> _initializeApp(int appStartTime) async {
  const envFileName = String.fromEnvironment(
    'ENV_FILE',
    defaultValue: '.env.prod',
  );

  // 初始化 GetStorage
  await GetStorage.init();

  // 加载环境变量
  await dotenv.load(fileName: 'env/$envFileName');
  final dstMap = Map.fromEntries(dotenv.env.entries);
  await dotenv.load(fileName: 'env/.env', mergeWith: dstMap);

  // 计算并记录启动耗时（从 Flutter 绑定初始化到核心配置完成）
  final cost = DateTime.now().millisecondsSinceEpoch - appStartTime;
  AppLogger.info('App核心初始化耗时: $cost ms');
  AppLogger.info('App启动环境: $envFileName');
}

/// 初始化非关键配置（延迟执行，不阻塞启动）
void _initializeNonCritical() {
  // 使用微任务延迟执行，确保 UI 已经渲染
  Future.microtask(() async {
    // 显示状态栏 + 底部导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    // 设置多语言（可以延迟，因为首次使用时会自动加载）
    Intl.defaultLocale = 'zh_CN';
    initializeDateFormatting('zh_CN', null).then((_) {
      if (kDebugMode) {
        debugPrint('多语言初始化完成');
      }
    });
  });
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
