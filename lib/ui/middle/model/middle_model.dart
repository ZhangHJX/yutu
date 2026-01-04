import 'package:json_annotation/json_annotation.dart';
part 'middle_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MiddleModel {
  int id;
  String title;
  String desc;
  String canvas;
  @JsonKey(name: 'canvas_size')
  String canvasSize;
  @JsonKey(name: 'original_image')
  String originalImage;
  @JsonKey(name: 'ordinary_image')
  String ordinaryImage;
  String thumbnail;
  @JsonKey(name: 'recources_url')
  String recourcesUrl;
  @JsonKey(name: 'favorite_total')
  int favoriteTotal;
  @JsonKey(name: 'is_official')
  int isOfficial;
  @JsonKey(name: 'is_favorite')
  int isFavorite;

  @JsonKey(name: 'front_data')
  List<FontItemModel> frontData;

  @JsonKey(name: 'tag_data')
  List<TagItemModel> tagData;

  MiddleModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.canvas,
    required this.canvasSize,
    required this.originalImage,
    required this.ordinaryImage,
    required this.thumbnail,
    required this.recourcesUrl,
    required this.favoriteTotal,
    required this.isOfficial,
    required this.isFavorite,
    required this.frontData,
    required this.tagData,
  });

  factory MiddleModel.fromJson(Map<String, dynamic> json) =>
      _$MiddleModelFromJson(json);

  Map<String, dynamic> toJson() => _$MiddleModelToJson(this);
}

@JsonSerializable()
class FontItemModel {
  @JsonKey(name: 'front_id')
  int frontId;

  @JsonKey(name: 'front_version')
  String frontVersion;

  FontItemModel({required this.frontId, required this.frontVersion});

  factory FontItemModel.fromJson(Map<String, dynamic> json) =>
      _$FontItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$FontItemModelToJson(this);
}

@JsonSerializable()
class TagItemModel {
  int id;
  String name;

  TagItemModel({required this.id, required this.name});

  factory TagItemModel.fromJson(Map<String, dynamic> json) =>
      _$TagItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagItemModelToJson(this);
}
