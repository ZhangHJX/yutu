import 'app_info_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoUtils {
  /// 获取完整的 App 信息
  static Future<AppInfoModel> getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfoModel(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }

  /// 只要版本号（常用）
  static Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version; // 比如 "1.0.3"
  }

  /// 版本号 + build 组合
  static Future<String> getFullVersion() async {
    final info = await PackageInfo.fromPlatform();
    // 例如：1.0.3 (42)
    return '${info.version} (${info.buildNumber})';
  }
}
