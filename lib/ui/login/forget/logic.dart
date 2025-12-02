import 'package:common/common.dart';
import 'dart:async';

class ForgetLogic extends GetxController {
  // 输入内容
  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;
  final again = ''.obs;

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

  Future<void> changePassWord() async {
    // showToast('验证码发送成功');
  }
}
