import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/stores/login_response.dart';
import '../../stores/global.dart';
import 'package:voicetemplate/core/index.dart';
import 'dart:async';
import 'model/code_model.dart';

class LoginLogic extends GetxController with WidgetsBindingObserver {
  /// 全局应用
  final global = Get.find<GlobalLogic>();

  final String? source = Get.arguments is String ? Get.arguments : null;

  // 输入内容
  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;

  // 协议状态
  final isAgreement = false.obs;

  // 登录类型状态,
  final isPasswordLogin = false.obs;
  final isPasswordVisible = false.obs;

  // 验证码相关状态
  final isCountingDown = false.obs;
  final countDown = 60.obs;
  // 计时器
  Timer? _timer;
  // 倒计时开始时间戳（毫秒）
  int? _countDownStartTime;
  // 倒计时总时长（秒）
  static const int _totalCountDownSeconds = 60;

  // 是否可以登录（响应式）
  final canLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 监听应用生命周期
    WidgetsBinding.instance.addObserver(this);
    // 监听相关状态变化，自动更新 canLogin
    everAll([phone, code, password, isPasswordLogin], (_) {
      _updateCanLogin();
    });
    _updateCanLogin(); // 初始化时计算一次
  }

  @override
  void onClose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && isCountingDown.value) {
      // 应用从后台恢复，重新计算倒计时
      _resumeCountDown();
    }
  }

  /// 更新 canLogin 状态
  void _updateCanLogin() {
    canLogin.value = phone.value.length == 11 && isSecondValid;
  }

  bool get isSecondValid {
    final codeText = code.value.trim();
    final passwordText = password.value.trim();
    if (isPasswordLogin.value) {
      // 密码 6-20 位
      return passwordText.length >= 6 && passwordText.length <= 20;
    } else {
      return codeText.length >= 4;
    }
  }

  // 切换密码可见性
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  // 切换密码/验证码登录
  void onTogglePasswordLogin(
    TextEditingController codeController,
    TextEditingController passwordController,
  ) {
    isPasswordLogin.toggle();
    // 清除密码或验证码
    if (isPasswordLogin.value) {
      codeController.clear();
    } else {
      passwordController.clear();
    }
  }

  Future<void> handleLogin() async {
    if (!isAgreement.value) {
      showToast('请先同意用户协议和隐私政策');
      return;
    }

    if (global.connectStatus.currentStatus == NetworkStatus.none) {
      showToast("登录失败");
      return;
    }

    if (isPasswordLogin.value) {
      handlePasswordLogin();
    } else {
      handleCodeLogin();
    }
  }

  // 处理密码登录
  Future<void> handlePasswordLogin() async {
    if (!isValidPassword(password.value)) {
      showToast("密码格式错误");
      return;
    }

    // 实现密码登录逻辑
    try {
      final result = await http.post<LoginResponse>(
        '/loginPassword/login',
        data: {'mobile': phone.value, 'password': password.value},
        converter: LoginResponse.fromJson,
        withToken: false,
      );
      if (result.code == 0) {
        global.accessToken.value = result.data?.token ?? '';
        await global.fetchUserInfo();

        if (source != null && source!.isNotEmpty) {
          EventBusManager.share.emit<String>(AppEventType.login, data: source);
        }

        Get.back();
      }
      // 返回上一个页面
    } catch (e) {
      debugPrint('=========== xxxxxxxxx error: $e');
    }
  }

  bool isValidPassword(String s) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9]{6,20}$').hasMatch(s);
  }

  // 处理验证码登录
  Future<void> handleCodeLogin() async {
    try {
      final result = await http.post<LoginResponse>(
        '/loginSms/login',
        data: {'mobile': phone.value, 'code': code.value},
        converter: LoginResponse.fromJson,
        withToken: false,
      );
      if (result.code == 0) {
        global.accessToken.value = result.data?.token ?? '';
        await global.fetchUserInfo();

        if (source != null && source!.isNotEmpty) {
          EventBusManager.share.emit<String>(AppEventType.login, data: source);
        }

        Get.back();
      }
    } catch (e) {
      debugPrint('=========== xxxxxxxxx error: $e');
    }
  }

  // 获取验证码
  Future<void> getVerificationCode(String phone) async {
    countDown.value = _totalCountDownSeconds;
    try {
      final result = await http.post<CodeModel>(
        "/loginSms/send",
        data: {"mobile": phone},
        converter: CodeModel.fromJson,
        withToken: false,
      );
      if (result.code == 0) {
        showToast('验证码发送成功');
        _startCountDown();
      } else {
        showToast('验证码发送失败');
      }
    } catch (e) {
      showToast('验证码发送失败');
      isCountingDown.value = false;
    }
  }

  /// 开始倒计时
  void _startCountDown() {
    _timer?.cancel();
    _countDownStartTime = DateTime.now().millisecondsSinceEpoch;
    isCountingDown.value = true;
    countDown.value = _totalCountDownSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountDown();
    });
  }

  /// 更新倒计时
  void _updateCountDown() {
    if (_countDownStartTime == null) {
      _stopCountDown();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - _countDownStartTime!) ~/ 1000;
    final remainingSeconds = _totalCountDownSeconds - elapsedSeconds;

    if (remainingSeconds > 0) {
      countDown.value = remainingSeconds;
    } else {
      _stopCountDown();
    }
  }

  /// 停止倒计时
  void _stopCountDown() {
    _timer?.cancel();
    _timer = null;
    _countDownStartTime = null;
    isCountingDown.value = false;
    countDown.value = 0;
  }

  /// 应用从后台恢复时重新计算倒计时
  void _resumeCountDown() {
    debugPrint('===========应用从后台恢复时重新计算倒计时========');

    if (_countDownStartTime == null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - _countDownStartTime!) ~/ 1000;
    final remainingSeconds = _totalCountDownSeconds - elapsedSeconds;

    if (remainingSeconds > 0) {
      countDown.value = remainingSeconds;
      // 如果计时器已停止，重新启动
      if (_timer == null || !_timer!.isActive) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateCountDown();
        });
      }
    } else {
      _stopCountDown();
    }
  }

  ///1、手机号验证
  void validatePhoneNumber() {
    if (phone.value.isEmpty) {
      showToast("请输入手机号");
      return;
    }
    getVerificationCode(phone.value);
  }

  void onUserAgreementTap() {
    Get.toNamed(AppRoutes.web, arguments: {'url': "https://www.baidu.com"});
  }

  void onPrivacyPolicyTap() {
    Get.toNamed(AppRoutes.web, arguments: {'url': "https://www.baidu.com"});
  }

  void onToggleAgreement() {
    isAgreement.toggle();
  }
}
