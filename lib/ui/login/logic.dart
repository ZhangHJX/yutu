import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../stores/global.dart';
import '../../app/routes/index.dart';
import 'dart:async';

class LoginLogic extends GetxController {
  /// 全局应用
  final globalLogic = Get.find<GlobalLogic>();

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

  // 是否可以登录（响应式）
  final canLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 监听相关状态变化，自动更新 canLogin
    everAll([phone, code, password, isPasswordLogin], (_) {
      _updateCanLogin();
    });
    _updateCanLogin(); // 初始化时计算一次
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
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

  Future<void> handleLogin(String phone, String password, String code) async {
    if (!isAgreement.value) {
      showToast('请先同意用户协议和隐私政策');
      return;
    }
    if (isPasswordLogin.value) {
      handlePasswordLogin(phone, password);
    } else {
      handleCodeLogin(phone, code);
    }
  }

  // 处理密码登录
  Future<void> handlePasswordLogin(String phone, String password) async {
    // 实现密码登录逻辑
    try {
      final result = await http.post(
        '/authPassword/login',
        data: {'mobile': phone, 'code': code},
      );
      debugPrint('=========== xxxxxxxxx error: $result');

      // globalLogic.accessToken.value = result.data?.accessToken ?? '';
      // globalLogic.fetchUserInfo();

      // 返回上一个页面
    } catch (e) {
      debugPrint('=========== xxxxxxxxx error: $e');
    }
  }

  // 处理验证码登录
  Future<void> handleCodeLogin(String phone, String code) async {
    try {
      final result = await http.post(
        '/authSms/login',
        data: {'mobile': phone, 'code': code},
      );
      debugPrint('=========== xxxxxxxxx error: $result');

      // globalLogic.accessToken.value = result.data?.accessToken ?? '';
      // globalLogic.fetchUserInfo();

      // 返回上一个页面
    } catch (e) {
      debugPrint('=========== xxxxxxxxx error: $e');
    }
  }

  // 获取验证码
  Future<void> getVerificationCode(String phone) async {
    isCountingDown.value = true;
    countDown.value = 60;

    try {
      final res = await http.post(
        "/authSms/send",
        data: {"mobile": phone},
        withToken: false,
      );

      debugPrint("----哈哈哈哈哈哈---$res-----");

      showToast('验证码发送成功');

      Timer.periodic(Duration(seconds: 1), (timer) {
        if (countDown.value > 0) {
          countDown.value--;
        } else {
          timer.cancel();
          isCountingDown.value = false;
        }
      });
    } catch (e) {
      showToast('验证码发送失败');
      isCountingDown.value = false;
    } finally {
      SmartDialog.dismiss();
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
