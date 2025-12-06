import 'package:common/common.dart';
import '../../core/index.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<GetStorageService>(GetStorageService(), permanent: true); // 单例

    // 这里只放“全局单例”的依赖
    // initCore();
  }

  static Future<void> initServices() async {
    await GetStorageService.init(); // 这里处理需要 async 的初始化（本地存储等）
  }

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
