import 'dart:convert';

class DraftModel {
  String uuid;
  String textJson;
  int timestamp;

  DraftModel({
    required this.uuid,
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
      uuid: map['uuid'] as String? ?? '',
      text: map['textJson'] != null
          ? jsonDecode(map['textJson'] as String) as Map<String, dynamic>
          : null,
      timestamp: map['timestamp'] as int?,
    );
  }

  /// 转换为 Map（用于保存到数据库）
  /// 注意：不包含 id 字段，因为数据库使用 uuid 作为唯一标识
  Map<String, dynamic> toMap() {
    return {'uuid': uuid, 'textJson': textJson, 'timestamp': timestamp};
  }
}
