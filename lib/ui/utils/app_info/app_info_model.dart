class AppInfoModel {
  /// App 显示名称（如：微信）
  final String appName;

  /// 包名（如：com.example.app）
  final String packageName;

  /// 版本号（对用户展示的，比如：1.2.3）
  final String version;

  /// 构建号 / buildNumber（比如：1、2、3，用来区分内部版本）
  final String buildNumber;

  AppInfoModel({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });
}
