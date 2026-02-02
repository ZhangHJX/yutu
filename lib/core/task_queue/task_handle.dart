/// 任务输入（Task）与输出（TaskHandle）定义。
library;

import 'cancel_token.dart';
import 'retry_strategy.dart';
import 'task_priority.dart';

/// 任务执行函数：接收 [CancelToken]，可选 [reportProgress] 上报进度，返回 [T]。
typedef TaskRunner<T, P> =
    Future<T> Function(
      CancelToken token,
      void Function(P progress)? reportProgress,
    );

/// 输入：Task(优先级, 超时, 重试策略, 可取消)。无进度时 P 用 [void]。
class Task<T, P> {
  final TaskPriority priority;
  final Duration? timeout;
  final RetryStrategy retryStrategy;
  final CancelToken? cancelToken;
  final TaskRunner<T, P> run;

  const Task({
    required this.priority,
    this.timeout,
    this.retryStrategy = const RetryStrategy(),
    this.cancelToken,
    required this.run,
  });
}

/// 输出：TaskHandle(future 结果, cancel(), progress stream 可选)。无进度时 P 用 [void]。
class TaskHandle<T, P> {
  final Future<T> future;
  final void Function() cancel;
  final Stream<P>? progressStream;

  TaskHandle({required this.future, required this.cancel, this.progressStream});
}
