import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../stores/global.dart';
import 'dart:async';

class LoginLogic extends GetxController {
  /// 全局应用
  final global = Get.find<GlobalLogic>();

  // 协议状态
  final isAgreement = false.obs;

  // 输入内容
  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;

  // 登录类型状态,
  final isPasswordLogin = false.obs;
  final isPasswordVisible = false.obs;

  // 验证码相关状态
  final isCountingDown = false.obs;
  final countDown = 60.obs;
  // 计时器
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  ///1、手机号验证
  void validatePhoneNumber() {
    if (phone.value.isEmpty) {
      showToast("请输入手机号");
      return;
    }
    getVerificationCode(phone.value);
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

  bool get canLogin =>
      phone.value.length == 11 && isSecondValid && isAgreement.value;

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

  // 获取验证码
  Future<void> getVerificationCode(String phone) async {
    showLoading('正在发送验证码...');

    isCountingDown.value = true;
    countDown.value = 60;

    try {
      // final model = await http.get(
      //   '/ds-app/member/sendLoginPassCode',
      //   query: {'phone': phone},
      //   converter: primitiveConverter<String>(),
      // );

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

  Future<void> handleLogin(String phone, String password, String code) async {
    if (!isAgreement.value) {
      return showToast('请先同意用户协议和隐私政策');
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
  }

  // 处理验证码登录
  Future<void> handleCodeLogin(String phone, String code) async {
    try {
      //   final result = await http.post(
      //     '/zx-auth/auth/app/login',
      //     data: {
      //       'loginType': 1,
      //       'phone': phone.replaceAll(' ', ''),
      //       'verifyCode': code,
      //       'codeId': codeId,
      //     },
      //     withToken: false,
      //     converter: LoginModel.fromJson,
      //     options: Options(
      //       headers: {
      //         'grant_type': 'authorization_code',
      //         'client_name': 'ds_app',
      //         'client_secret': '7bcfb79e9826fc98a726d110dcee0ee1',
      //       },
      //     ),
      //   );
      //   globalLogic.accessToken.value = result.data?.accessToken ?? '';

      // globalLogic.fetchUserInfo();

      // 返回上一个页面
      Get.back();
    } catch (e) {
      debugPrint('=========== xxxxxxxxx error: $e');
    }
  }

  void onUserAgreementTap() {
    // openWeb('https://www.baidu.com');
  }

  void onPrivacyPolicyTap() {
    // openWeb('https://www.jd.com');
  }

  void onToggleAgreement() {
    isAgreement.toggle();
  }
}
