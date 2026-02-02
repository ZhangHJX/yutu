import 'package:common/common.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import '../model/code_model.dart';
import '../model/phone_model.dart';
import '../../../stores/global.dart';
import 'package:voicetemplate/core/index.dart';

class ForgetLogic extends GetxController {
  /// 全局应用
  final global = Get.find<GlobalLogic>();

  // 输入内容
  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;
  final again = ''.obs;

  /// TextField 控制器放在 Logic 里管理
  late final TextEditingController phoneController;

  // 验证码相关状态
  final isCountingDown = false.obs;
  final countDown = 60.obs;

  final isNewPasswordVisible = false.obs;
  final isAgainPasswordVisible = false.obs;

  // 计时器
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // 初始化 TextEditingController
    if (global.isLogin) {
      phoneController = TextEditingController(text: phone.value);
      getPhoneNumber();
    } else {
      phoneController = TextEditingController();
    }
    ever<String>(phone, (value) {
      if (phoneController.text != value) {
        phoneController.text = value;
      }
    });
  }

  Future<void> changePassWord() async {
    try {
      if (password.value != again.value) {
        showToast("两次输入的密码不一致");
        return;
      }

      if (!isValidPassword(password.value)) {
        showToast("密码格式错误");
        return;
      }

      if (global.connectStatus.currentStatus == Status.none) {
        showToast("设置失败");
        return;
      }

      final result = await http.post(
        global.isLogin
            ? '/passwordSet/setPassword'
            : '/passwordChange/changePassword',
        data: global.isLogin
            ? {"password": password.value, "code": code.value}
            : {
                "mobile": phone.value,
                "code": code.value,
                "password": password.value,
              },
        withToken: global.isLogin,
      );
      if (result.code == 0) {
        Get.back();
      }
    } catch (e) {
      AppLogger.error('设置和忘记密码接口报错', e);
    }
  }

  ///1、获取手机号码
  void getPhoneNumber() async {
    AppLogger.info('获取手机号的接口');

    final result = await http.post<PhoneModel>(
      "/passwordSet/index",
      converter: PhoneModel.fromJson,
      withToken: global.isLogin,
    );
    if (result.data != null) {
      phone.value = result.data!.mobile;
    }
  }

  ///1、手机号验证
  void validatePhoneNumber() {
    if (phone.value.isEmpty) {
      showToast("请输入手机号");
      return;
    }
    getVerificationCode();
  }

  ///2、获取验证码
  /// 忘记密码不需要 token，要手机号
  /// 设置密码： 全都需要token
  Future<void> getVerificationCode() async {
    isCountingDown.value = true;
    countDown.value = 60;
    try {
      final result = await http.post<CodeModel>(
        global.isLogin ? "/passwordSet/sendSms" : '/passwordChange/sendSms',
        data: global.isLogin ? {} : {'mobile': phone.value},
        converter: CodeModel.fromJson,
        withToken: global.isLogin,
      );

      if (result.code == 0) {
        showToast('验证码发送成功');
        Timer.periodic(Duration(seconds: 1), (timer) {
          if (countDown.value > 0) {
            countDown.value--;
          } else {
            timer.cancel();
            isCountingDown.value = false;
          }
        });
      } else {
        showToast('验证码发送失败');
      }
    } catch (e) {
      showToast('验证码发送失败');
      isCountingDown.value = false;
    }
  }

  // 切换密码可见性
  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.toggle();
  }

  void toggleAgainPasswordVisibility() {
    isAgainPasswordVisible.toggle();
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    super.onClose();
  }
}
