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

  MiddleModel copyWith({
    int? id,
    String? title,
    String? desc,
    String? canvas,
    String? canvasSize,
    String? originalImage,
    String? ordinaryImage,
    String? thumbnail,
    String? recourcesUrl,
    int? favoriteTotal,
    int? isOfficial,
    int? isFavorite,
    List<FontItemModel>? frontData,
    List<TagItemModel>? tagData,
  }) {
    return MiddleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      canvas: canvas ?? this.canvas,
      canvasSize: canvasSize ?? this.canvasSize,
      originalImage: originalImage ?? this.originalImage,
      ordinaryImage: ordinaryImage ?? this.ordinaryImage,
      thumbnail: thumbnail ?? this.thumbnail,
      recourcesUrl: recourcesUrl ?? this.recourcesUrl,
      favoriteTotal: favoriteTotal ?? this.favoriteTotal,
      isOfficial: isOfficial ?? this.isOfficial,
      isFavorite: isFavorite ?? this.isFavorite,
      frontData: frontData ?? this.frontData,
      tagData: tagData ?? this.tagData,
    );
  }
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

  FontItemModel copyWith({int? frontId, String? frontVersion}) {
    return FontItemModel(
      frontId: frontId ?? this.frontId,
      frontVersion: frontVersion ?? this.frontVersion,
    );
  }
}

@JsonSerializable()
class TagItemModel {
  final int id;
  final String name;

  TagItemModel({required this.id, required this.name});

  factory TagItemModel.fromJson(Map<String, dynamic> json) =>
      _$TagItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagItemModelToJson(this);

  TagItemModel copyWith({int? id, String? name}) {
    return TagItemModel(id: id ?? this.id, name: name ?? this.name);
  }
}
