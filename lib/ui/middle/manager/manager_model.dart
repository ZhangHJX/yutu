/// DraftModel 只代表"业务草稿数据"：
/// - id：业务侧的草稿标识（例如 CanvasModel.id） （如 canvasId），
/// - timestamp：时间戳（秒）
/// 数据库内部主键（自增 id）对业务层透明。
class ManagerModel {
  /// 业务侧草稿 id（例如 CanvasModel.id）
  int id;
  int timestamp;

  ManagerModel({required this.id, int? timestamp})
    : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// 从 Map 创建 DraftModel（用于从数据库读取）
  factory ManagerModel.fromMap(Map<String, dynamic> map) {
    return ManagerModel(
      id: map['canvasId'] as int? ?? 0,
      timestamp: map['timestamp'] as int?,
    );
  }

  /// 转换为 Map（用于保存到数据库）
  /// 注意：这里的 id 映射到表中的 canvasId 列
  Map<String, dynamic> toMap() {
    return {'canvasId': id, 'timestamp': timestamp};
  }
}
