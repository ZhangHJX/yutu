import 'package:json_annotation/json_annotation.dart';

part 'image_list_models.g.dart';

@JsonSerializable(explicitToJson: true)
class ImageListModels {
  @JsonKey(name: 'list', defaultValue: [])
  final List<ImageModel> items;

  @JsonKey(defaultValue: 1)
  final int page;

  @JsonKey(defaultValue: 10)
  final int pageSize;

  ImageListModels({
    required this.items,
    required this.page,
    required this.pageSize,
  });

  factory ImageListModels.fromJson(Map<String, dynamic> json) =>
      _$ImageListModelsFromJson(json);

  Map<String, dynamic> toJson() => _$ImageListModelsToJson(this);
}

@JsonSerializable()
class ImageModel {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: '')
  final String image;

  @JsonKey(name: 'file_size', defaultValue: '')
  final String fileSize;

  @JsonKey(name: 'canvas_size', defaultValue: '')
  final String canvasSize;

  ImageModel({
    required this.id,
    required this.image,
    required this.fileSize,
    required this.canvasSize,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) =>
      _$ImageModelFromJson(json);
  Map<String, dynamic> toJson() => _$ImageModelToJson(this);
}
