import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// GetX Controller 的 TickerProvider Mixin
/// 用于在 GetxController 中提供 TickerProvider 功能
/// 类似于 SingleTickerProviderStateMixin，但用于 Controller
mixin SingleGetTickerProviderMixin on GetxController {
  TickerProvider? _tickerProvider;

  /// 获取 TickerProvider
  TickerProvider? get tickerProvider => _tickerProvider;

  /// 初始化 TickerProvider
  /// 需要在 State 中调用，传入 SingleTickerProviderStateMixin 的实例
  void initTickerProvider(TickerProvider tickerProvider) {
    _tickerProvider = tickerProvider;
  }

  /// 清理 TickerProvider
  void disposeTickerProvider() {
    _tickerProvider = null;
  }
}

