import 'package:common/common.dart';

part 'image_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ImageModel {
  int id;
  String url;
  String? thumbnail;
  String? name;
  int? width;
  int? height;

  ImageModel({
    required this.id,
    required this.url,
    this.thumbnail,
    this.name,
    this.width,
    this.height,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) =>
      _$ImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ImageModelToJson(this);
}
