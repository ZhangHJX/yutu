import 'package:common/common.dart';
import 'package:voicetemplate/ui/canvas/fonts/font_manager.dart';
import 'package:voicetemplate/ui/middle/manager/index.dart';

// Binding 只负责 new 对象 + Get.put
class AppBinding extends Bindings {
  @override
  void dependencies() async {
    Get.put<FontManager>(FontManager(), permanent: true);

    // 初始化 ObjectBox
    await DraftStore.instance.init();

    // Get.put<GetStorageService>(
    //   GetStorageService(GetStorage('app_storage')),
    //   permanent: true,
    // );
  }

  /// 这里只放“全局单例”的依赖
  // static void initCore() {
  //   // ApiClient 单例
  //   Get.put<ApiClient>(ApiClient(), permanent: true);
  // }

  /// 根据模块进行注册，避免所有东西都堆到一个 Binding 里
  // static void registerAuthModule() {
  //   // local storage service 单例
  //   if (!Get.isRegistered<StorageService>()) {
  //     Get.put<StorageService>(StorageService(), permanent: true);
  //   }

  //   // DataSources
  //   Get.lazyPut<AuthRemoteDataSource>(
  //     () => AuthRemoteDataSourceImpl(Get.find<ApiClient>()),
  //   );
  //   Get.lazyPut<AuthLocalDataSource>(
  //     () => AuthLocalDataSourceImpl(Get.find<StorageService>()),
  //   );

  //   // Repository
  //   Get.lazyPut<AuthRepository>(
  //     () => AuthRepositoryImpl(
  //       remoteDataSource: Get.find<AuthRemoteDataSource>(),
  //       localDataSource: Get.find<AuthLocalDataSource>(),
  //     ),
  //   );

  //   // UseCase
  //   Get.lazyPut<LoginUseCase>(() => LoginUseCase(Get.find<AuthRepository>()));

  //   // Controller
  //   Get.lazyPut<AuthController>(() => AuthController(Get.find<LoginUseCase>()));
  // }
}
