import 'package:common/common.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import '../model/code_model.dart';
import '../model/phone_model.dart';
import '../../../stores/global.dart';

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
      final result = await http.post(
        global.isLogin
            ? '/passwordSet/setPassword'
            : 'passwordChange/changePassword',
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
      debugPrint('===========  error: $e');
    }
  }

  ///1、获取手机号码
  void getPhoneNumber() async {
    final result = await http.post<PhoneModel>(
      "/passwordSet/index",
      converter: PhoneModel.fromJson,
      showErrorToast: false,
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
      await http.post<CodeModel>(
        global.isLogin ? "/passwordSet/sendSms" : '/passwordChange/sendSms',
        data: global.isLogin ? {} : {'mobile': phone.value},
        converter: CodeModel.fromJson,
        showErrorToast: true,
        withToken: global.isLogin,
      );

      Timer.periodic(Duration(seconds: 1), (timer) {
        if (countDown.value > 0) {
          countDown.value--;
        } else {
          timer.cancel();
          isCountingDown.value = false;
        }
      });
    } catch (e) {
      isCountingDown.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    super.onClose();
  }
}
