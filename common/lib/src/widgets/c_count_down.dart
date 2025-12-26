import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CCountDown extends HookWidget {
  const CCountDown({super.key, this.seconds = 0, this.onEnd, this.textStyle, this.leading});

  final int seconds;
  final VoidCallback? onEnd;
  final TextStyle? textStyle;
  final String? leading;

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = useState(seconds);
    final timer = useRef<Timer?>(null);

    useEffect(() {
      if (seconds <= 0) {
        return null;
      }

      remainingSeconds.value = seconds;

      timer.value = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (remainingSeconds.value > 0) {
          remainingSeconds.value--;
        } else {
          t.cancel();
          onEnd?.call();
        }
      });

      return () => timer.value?.cancel();
    }, [seconds]);

    final TextStyle defaultStyle = .new(color: '#FFEA3A45'.color, fontSize: 14.w);

    return DefaultTextStyle(
      style: defaultStyle.merge(textStyle),
      child: Text(
        leading == null
            ? secondsToDate(remainingSeconds.value)
            : '$leading${secondsToDate(remainingSeconds.value)}',
      ),
    );
  }
}
