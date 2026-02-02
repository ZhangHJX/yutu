/// 取消令牌：任务启动前取消 = 直接丢弃；启动后取消 = 协作式中断（任务内需检查 [throwIfCancelled]）。
library;

import 'dart:async';

class CancelToken {
  bool _cancelled = false;
  final _controller = StreamController<void>.broadcast();

  bool get isCancelled => _cancelled;

  /// 取消时触发的流（可选监听）
  Stream<void> get onCancel => _controller.stream;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _controller.add(null);
  }

  /// 若已取消则抛出 [TaskCancelledException]（协作式中断）
  void throwIfCancelled() {
    if (_cancelled) throw TaskCancelledException();
  }

  void dispose() {
    _controller.close();
  }
}

class TaskCancelledException implements Exception {
  @override
  String toString() => 'TaskCancelledException';
}
