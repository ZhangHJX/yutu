import 'dart:convert';

/// DraftModel 只代表“业务草稿数据”：
/// - id：业务侧的草稿标识（例如 CanvasModel.id）
/// - textJson：画布 JSON 数据
/// - timestamp：时间戳（秒）
///
/// 数据库存储结构中，业务 id 会映射到单独的整数列（如 canvasId），
/// 数据库内部主键（自增 id）对业务层透明。
class DraftModel {
  /// 业务侧草稿 id（例如 CanvasModel.id）
  int id;
  String textJson;
  int timestamp;

  DraftModel({
    required this.id,
    Map<String, dynamic>? text, // 你想要的 json
    int? timestamp,
  }) : textJson = jsonEncode(text ?? {}),
       timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // 不入库：使用时像 json 一样访问
  Map<String, dynamic> get text =>
      (jsonDecode(textJson) as Map).cast<String, dynamic>();

  set text(Map<String, dynamic> v) => textJson = jsonEncode(v);

  /// 从 Map 创建 DraftModel（用于从数据库读取）
  factory DraftModel.fromMap(Map<String, dynamic> map) {
    return DraftModel(
      id: map['canvasId'] as int? ?? 0,
      text: map['textJson'] != null
          ? jsonDecode(map['textJson'] as String) as Map<String, dynamic>
          : null,
      timestamp: map['timestamp'] as int?,
    );
  }

  /// 转换为 Map（用于保存到数据库）
  /// 注意：这里的 id 映射到表中的 canvasId 列
  Map<String, dynamic> toMap() {
    return {'canvasId': id, 'textJson': textJson, 'timestamp': timestamp};
  }
}
