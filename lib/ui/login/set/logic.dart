import 'package:common/common.dart';
import 'dart:async';

class SetLogic extends GetxController {
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

  Future<void> savePassWord() async {
    // showToast('验证码发送成功');
  }
}
