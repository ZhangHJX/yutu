/// 任务调度器 TaskQueue
///
/// 能力：优先级(high/normal/low)、maxConcurrent、CancelToken、每任务超时、重试(指数退避+抖动)、同优先级 FIFO。
library;

import 'dart:async';

import 'cancel_token.dart';
import 'task_handle.dart';
import 'task_priority.dart';

/// 队列内待执行项（带入队顺序保证同优先级 FIFO）
class _QueuedTask<T, P> {
  final Task<T, P> task;
  final int enqueueOrder; // 入队序号，同优先级时按这个 FIFO
  final Completer<T> completer;
  final CancelToken? externalToken;
  StreamController<P>? progressController;

  _QueuedTask({
    required this.task,
    required this.enqueueOrder,
    required this.completer,
    this.externalToken,
    this.progressController,
  });
}

class TaskQueue {
  final int maxConcurrent;

  int _enqueueCounter = 0;
  int _runningCount = 0;
  final List<_QueuedTask<dynamic, dynamic>> _queue = [];

  TaskQueue({this.maxConcurrent = 4}) {
    if (maxConcurrent < 1) throw ArgumentError('maxConcurrent must be >= 1');
  }

  /// 按优先级排序（high=0, normal=1, low=2），同优先级按 enqueueOrder FIFO
  void _sortQueue() {
    _queue.sort((a, b) {
      final pa = a.task.priority.order;
      final pb = b.task.priority.order;
      if (pa != pb) return pa.compareTo(pb);
      return a.enqueueOrder.compareTo(b.enqueueOrder);
    });
  }

  /// 提交任务，返回 [TaskHandle]
  TaskHandle<T, P> submit<T, P>(Task<T, P> task) {
    final completer = Completer<T>();
    final token = task.cancelToken ?? CancelToken();
    final progressController = StreamController<P>.broadcast();

    final queued = _QueuedTask<T, P>(
      task: task,
      enqueueOrder: _enqueueCounter++,
      completer: completer,
      externalToken: task.cancelToken == null ? token : null,
      progressController: progressController,
    );

    void doCancel() {
      token.cancel();
    }

    final handle = TaskHandle<T, P>(
      future: completer.future,
      cancel: doCancel,
      progressStream: progressController.stream,
    );

    _queue.add(queued as _QueuedTask<dynamic, dynamic>);
    _sortQueue();
    _drain();

    return handle;
  }

  void _drain() {
    while (_runningCount < maxConcurrent && _queue.isNotEmpty) {
      final first = _queue.first;
      final token = first.externalToken ?? first.task.cancelToken;
      if (token != null && token.isCancelled) {
        _queue.removeAt(0);
        _closeProgress(first);
        first.completer.completeError(TaskCancelledException());
        continue;
      }
      _queue.removeAt(0);
      _runningCount++;
      _runTask(first).whenComplete(() {
        _runningCount--;
        _drain();
      });
    }
  }

  void _closeProgress(_QueuedTask<dynamic, dynamic> queued) {
    try {
      queued.progressController?.close();
    } catch (_) {}
  }

  Future<void> _runTask(_QueuedTask<dynamic, dynamic> queued) async {
    final task = queued.task;
    final token = queued.externalToken ?? task.cancelToken;
    final retry = task.retryStrategy;
    int attempt = 0;

    while (true) {
      token?.throwIfCancelled();

      final t = token ?? CancelToken();
      void Function(dynamic)? reportProgress;
      final progressController = queued.progressController;
      if (progressController != null) {
        reportProgress = (p) {
          if (!progressController.isClosed) progressController.add(p);
        };
      }

      Future<dynamic> runOne() async {
        t.throwIfCancelled();
        return task.run(t, reportProgress);
      }

      final withTimeout = task.timeout != null
          ? runOne().timeout(
              task.timeout!,
              onTimeout: () => throw TimeoutException('Task timeout'),
            )
          : runOne();

      try {
        final result = await withTimeout;
        _closeProgress(queued);
        if (!queued.completer.isCompleted) queued.completer.complete(result);
        return;
      } catch (e, st) {
        token?.throwIfCancelled();
        if (attempt >= retry.maxRetries) {
          _closeProgress(queued);
          if (!queued.completer.isCompleted) {
            queued.completer.completeError(e, st);
          }
          return;
        }
        final delay = retry.delayForAttempt(attempt);
        await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }
}
