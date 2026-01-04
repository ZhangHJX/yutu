import 'package:json_annotation/json_annotation.dart';
part 'middle_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MiddleModel {
  final int id;
  final String title;
  final String desc;
  final String canvas;
  @JsonKey(name: 'canvas_size')
  final String canvasSize;
  @JsonKey(name: 'original_image')
  final String originalImage;
  @JsonKey(name: 'ordinary_image')
  final String ordinaryImage;
  final String thumbnail;
  @JsonKey(name: 'recources_url')
  final String recourcesUrl;
  @JsonKey(name: 'favorite_total')
  final int favoriteTotal;
  @JsonKey(name: 'is_official')
  final int isOfficial;
  @JsonKey(name: 'is_favorite')
  final int isFavorite;

  @JsonKey(name: 'front_data')
  final List<FontItemModel> frontData;

  @JsonKey(name: 'tag_data')
  final List<TagItemModel> tagData;

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
  final int frontId;

  @JsonKey(name: 'front_version')
  final String frontVersion;

  FontItemModel({required this.frontId, required this.frontVersion});

  factory FontItemModel.fromJson(Map<String, dynamic> json) =>
      _$FontItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$FontItemModelToJson(this);
}

@JsonSerializable()
class TagItemModel {
  final int id;
  final String name;

  TagItemModel({required this.id, required this.name});

  factory TagItemModel.fromJson(Map<String, dynamic> json) =>
      _$TagItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagItemModelToJson(this);
}
