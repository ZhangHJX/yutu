import 'package:json_annotation/json_annotation.dart';

part 'save_response.g.dart';

@JsonSerializable(explicitToJson: true)
class SaveResponse {
  int id;
  SaveResponse({this.id = 0});

  // 自动生成的 JSON 解析
  factory SaveResponse.fromJson(Map<String, dynamic> json) =>
      _$SaveResponseFromJson(json);

  /// 自动生成的 JSON 输出
  Map<String, dynamic> toJson() => _$SaveResponseToJson(this);
}
