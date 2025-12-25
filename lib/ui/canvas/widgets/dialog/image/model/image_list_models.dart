import 'package:common/common.dart';
part 'image_list_models.g.dart';

@JsonSerializable(explicitToJson: true)
class ImageListModels {
  @JsonKey(name: 'list')
  final List<ImageModel> items;
  final int page;
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
  final int id;

  final String image;

  @JsonKey(name: 'file_size')
  final String fileSize;

  @JsonKey(name: 'canvas_size')
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
