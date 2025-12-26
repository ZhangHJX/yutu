import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/material.dart';

class LoadingHelper {
  LoadingHelper({
    this.message,
    this.onLoadingChanged,
    this.delay = const Duration(milliseconds: 250),
    this.minDuration = const Duration(milliseconds: 1000),
  });

  final Duration delay;
  final Duration minDuration;
  final String? message;
  final ValueChanged<bool>? onLoadingChanged;

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
        if (onLoadingChanged == null) {
          showLoading(message ?? '加载中...');
        } else {
          onLoadingChanged!.call(true);
        }
        loadingShown = true;
        showTime = DateTime.now();
      });

      final result = await func();
      await ensureMinDuration();
      if (onLoadingChanged == null) {
        SmartDialog.dismiss(status: SmartStatus.loading);
      } else {
        onLoadingChanged!.call(false);
      }
      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      if (onLoadingChanged == null) {
        SmartDialog.dismiss(status: SmartStatus.loading);
      } else if (loadingShown) {
        onLoadingChanged!.call(false);
      }
      onError?.call(e, stack);
      rethrow;
    } finally {
      delayTimer?.cancel();
    }
  }
}

Future<T> performWithLoading<T>(
  AsyncFunc<T> func, {
  String? message,
  Duration delay = const Duration(milliseconds: 250),
  Duration minDuration = const Duration(milliseconds: 1000),
  void Function(bool loading)? onLoadingChanged,
  void Function(T result)? onSuccess,
  void Function(Object error, StackTrace stack)? onError,
}) {
  return LoadingHelper(
    onLoadingChanged: onLoadingChanged,
    message: message,
    delay: delay,
    minDuration: minDuration,
  ).runWithLoading(func, onSuccess: onSuccess, onError: onError);
}
