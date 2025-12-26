import 'dart:async';
import 'dart:ui';

import 'package:flutter_hooks/flutter_hooks.dart';

class CountdownResult {
  CountdownResult({
    required this.seconds,
    required this.isRunning,
    required this.start,
    required this.stop,
    required this.isEverEnd,
  });

  /// 倒计时剩余的秒数
  final int seconds;

  /// 是否正在倒计时
  final bool isRunning;

  /// 开始倒计时
  final VoidCallback start;

  /// 停止倒计时
  final VoidCallback stop;

  /// 是否倒计时结束过
  final bool isEverEnd;
}

/// 专门用作获取验证码等可交互的倒计时
CountdownResult useCountdown({
  required int countStart,
  Duration interval = const Duration(seconds: 1),
}) {
  final seconds = useState(countStart);
  final isRunning = useState(false);
  final timerRef = useRef<Timer?>(null);

  final isEnded = useState(false);

  void start() {
    if (isRunning.value) {
      return;
    }
    isRunning.value = true;
    seconds.value = countStart;

    timerRef.value = Timer.periodic(interval, (timer) {
      if (seconds.value < 1) {
        timer.cancel();
        isRunning.value = false;
        isEnded.value = true;
        seconds.value = countStart;
      } else {
        seconds.value--;
      }
    });
  }

  void stop() {
    timerRef.value?.cancel();
    timerRef.value = null;
    isRunning.value = false;
    seconds.value = countStart;
  }

  useEffect(() {
    return () {
      timerRef.value?.cancel();
    };
  }, []);

  return CountdownResult(
    seconds: seconds.value,
    isRunning: isRunning.value,
    start: start,
    stop: stop,
    isEverEnd: isEnded.value,
  );
}
