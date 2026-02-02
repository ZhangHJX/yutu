/// 重试策略：指数退避 + 抖动，避免雪崩。
library;

import 'dart:math';

class RetryStrategy {
  /// 最大重试次数（不含首次执行）
  final int maxRetries;

  /// 基础延迟，第一次重试前等待 baseDelay
  final Duration baseDelay;

  /// 抖动系数 0~1，实际延迟 = baseDelay * 2^attempt * (1 ± jitterFactor 内随机)
  final double jitterFactor;

  const RetryStrategy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.jitterFactor = 0.3,
  });

  static final _random = Random();

  /// 第 [attempt] 次重试前的等待时间（指数退避 + 抖动）
  Duration delayForAttempt(int attempt) {
    final exponential = baseDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitter = exponential * jitterFactor * (2 * _random.nextDouble() - 1);
    final ms = (exponential + jitter).clamp(0, double.infinity).toInt();
    return Duration(milliseconds: ms);
  }
}
