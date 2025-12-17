import 'package:common/common.dart';

part 'font_info_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FontInfoModel {
  int id;
  String version;
  String name;
  String image;
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
