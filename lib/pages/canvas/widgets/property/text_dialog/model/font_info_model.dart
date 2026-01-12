import 'package:json_annotation/json_annotation.dart';

part 'font_info_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FontInfoModel {
  @JsonKey(defaultValue: 0)
  int id;

  @JsonKey(defaultValue: '')
  String version;

  @JsonKey(defaultValue: '')
  String name;

  @JsonKey(defaultValue: '')
  String image;

  @JsonKey(defaultValue: '')
  String url;

  FontInfoModel({
    required this.id,
    required this.version,
    required this.name,
    required this.image,
    required this.url,
  });

  factory FontInfoModel.fromJson(Map<String, dynamic> json) =>
      _$FontInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$FontInfoModelToJson(this);
}
