import 'dart:async';

class Throttler {
  Throttler({required this.interval});
  final Duration interval;
  Timer? _timer;
  bool _locked = false;

  void call(void Function() action) {
    if (_locked) return;
    _locked = true;
    action();

    _timer?.cancel();
    _timer = Timer(interval, () {
      _locked = false;
    });
  }

  void dispose() => _timer?.cancel();
}
