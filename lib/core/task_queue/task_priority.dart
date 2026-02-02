/// 任务优先级：high / normal / low，同优先级 FIFO。
library;

enum TaskPriority { high, normal, low }

extension TaskPriorityOrder on TaskPriority {
  /// 排序用：数值越小越先执行。
  int get order {
    switch (this) {
      case TaskPriority.high:
        return 0;
      case TaskPriority.normal:
        return 1;
      case TaskPriority.low:
        return 2;
    }
  }
}
