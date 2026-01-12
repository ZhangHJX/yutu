/// 命令基类
///
/// 所有需要支持撤销/重做的操作都应该实现此接口
abstract class CanvasCommand {
  /// 执行命令
  void execute();

  /// 撤销命令
  void undo();

  /// 获取命令描述（用于调试和日志）
  String get description;
}
