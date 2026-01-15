import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络连接状态枚举
enum NetworkStatus {
  /// 无网络连接
  none,

  /// WiFi 连接
  wifi,

  /// 移动网络连接
  mobile,

  /// 其他连接方式（如以太网）
  other,
}

/// 网络连接监听服务（单例）
class ConnectivityService {
  /// 私有构造函数
  ConnectivityService._internal() {
    _connectivity = Connectivity();
    _init();
  }

  /// 单例实例
  static ConnectivityService? _instance;

  /// 获取单例实例
  factory ConnectivityService() {
    _instance ??= ConnectivityService._internal();
    return _instance!;
  }

  late Connectivity _connectivity;
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.none;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 当前网络状态
  NetworkStatus get currentStatus => _currentStatus;

  /// 网络状态变化流
  Stream<NetworkStatus> get onStatusChanged => _controller.stream;

  /// 是否有网络连接
  bool get hasConnection => _currentStatus != NetworkStatus.none;

  /// 是否为 WiFi 连接
  bool get isWifi => _currentStatus == NetworkStatus.wifi;

  /// 是否为移动网络连接
  bool get isMobile => _currentStatus == NetworkStatus.mobile;

  /// 初始化
  Future<void> _init() async {
    // 获取初始状态
    await _checkConnectivity();

    // 监听网络状态变化
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        _controller.addError(error);
      },
    );
  }

  /// 检查当前网络连接状态
  Future<NetworkStatus> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity();
      final status = _convertToNetworkStatus(results);
      _currentStatus = status;
      return status;
    } catch (e) {
      _currentStatus = NetworkStatus.none;
      return NetworkStatus.none;
    }
  }

  /// 处理网络状态变化
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final status = _convertToNetworkStatus(results);
    if (_currentStatus != status) {
      _currentStatus = status;
      _controller.add(status);
    }
  }

  /// 将 ConnectivityResult 转换为 NetworkStatus
  NetworkStatus _convertToNetworkStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.none;
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkStatus.wifi;
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkStatus.mobile;
    }

    // 其他连接方式（如以太网、蓝牙等）
    return NetworkStatus.other;
  }

  /// 手动检查网络状态（返回当前状态）
  Future<NetworkStatus> checkConnectivity() async {
    return await _checkConnectivity();
  }

  /// 获取详细的连接结果列表
  Future<List<ConnectivityResult>> getConnectivityResults() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return [ConnectivityResult.none];
    }
  }

  /// 释放资源
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _instance = null;
  }
}
