import 'dart:async';

import 'package:common/common.dart';

class LoadingHelper {
  LoadingHelper({
    required this.message,
    this.delay = const Duration(milliseconds: 250),
    this.minDuration = const Duration(milliseconds: 1000),
  });

  final Duration delay;
  final Duration minDuration;
  final String message;

  Future<T> runWithLoading<T>(
    AsyncFunc<T> func, {
    void Function(T result)? onSuccess,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    bool loadingShown = false;
    DateTime? showTime;
    Timer? delayTimer;

    Future<void> ensureMinDuration() async {
      if (loadingShown && showTime != null) {
        final elapsed = DateTime.now().difference(showTime!);
        if (elapsed < minDuration) {
          await Future.delayed(minDuration - elapsed);
        }
      }
    }

    try {
      delayTimer = Timer(delay, () {
        showLoading(message);
        loadingShown = true;
        showTime = DateTime.now();
      });

      final result = await func();
      await ensureMinDuration();
      SmartDialog.dismiss(status: SmartStatus.loading);
      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      onError?.call(e, stack);
      rethrow;
    } finally {
      delayTimer?.cancel();
    }
  }
}

Future<T> performWithLoading<T>(
  String message,
  AsyncFunc<T> func, {
  Duration delay = const Duration(milliseconds: 250),
  Duration minDuration = const Duration(milliseconds: 1000),
  void Function(T result)? onSuccess,
  void Function(Object error, StackTrace stack)? onError,
}) {
  return LoadingHelper(
    message: message,
    delay: delay,
    minDuration: minDuration,
  ).runWithLoading(func, onSuccess: onSuccess, onError: onError);
}
