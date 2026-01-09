import 'package:json_annotation/json_annotation.dart';
part 'middle_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MiddleModel {
  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(name: 'edit_time', defaultValue: 0)
  final int editTime;
  @JsonKey(defaultValue: '')
  final String title;
  @JsonKey(defaultValue: '')
  final String desc;
  @JsonKey(defaultValue: '')
  final String canvas;
  @JsonKey(name: 'canvas_size', defaultValue: '')
  final String canvasSize;
  @JsonKey(name: 'original_image', defaultValue: '')
  final String originalImage;
  @JsonKey(name: 'ordinary_image', defaultValue: '')
  final String ordinaryImage;
  @JsonKey(defaultValue: '')
  final String thumbnail;
  @JsonKey(name: 'recources_url', defaultValue: '')
  final String recourcesUrl;
  @JsonKey(name: 'favorite_total', defaultValue: 0)
  final int favoriteTotal;
  @JsonKey(name: 'is_official', defaultValue: 0)
  final int isOfficial;
  @JsonKey(name: 'is_favorite', defaultValue: 0)
  final int isFavorite;

  @JsonKey(name: 'front_data', defaultValue: [])
  final List<FontItemModel> frontData;

  @JsonKey(name: 'tag_data', defaultValue: [])
  final List<TagItemModel> tagData;

  ///新增 是否是自己  0 否   1 是
  @JsonKey(name: 'is_own', defaultValue: 0)
  final int isOwn;

  MiddleModel({
    required this.id,
    required this.editTime,
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
    required this.isOwn,
  });

  factory MiddleModel.fromJson(Map<String, dynamic> json) =>
      _$MiddleModelFromJson(json);

  Map<String, dynamic> toJson() => _$MiddleModelToJson(this);

  MiddleModel copyWith({
    int? id,
    int? editTime,
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
    int? isOwn,
  }) {
    return MiddleModel(
      id: id ?? this.id,
      editTime: this.editTime,
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
      isOwn: isOwn ?? this.isOwn,
    );
  }
}

@JsonSerializable()
class FontItemModel {
  @JsonKey(name: 'front_id', defaultValue: 0)
  final int id;

  @JsonKey(name: 'front_version', defaultValue: '')
  final String version;

  @JsonKey(name: 'front_name', defaultValue: '')
  final String name;

  @JsonKey(name: 'front_image', defaultValue: '')
  final String image;

  @JsonKey(name: 'front_url', defaultValue: '')
  final String url;

  FontItemModel({
    required this.id,
    required this.version,
    required this.name,
    required this.image,
    required this.url,
  });

  factory FontItemModel.fromJson(Map<String, dynamic> json) =>
      _$FontItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$FontItemModelToJson(this);

  FontItemModel copyWith({
    int? id,
    String? version,
    String? name,
    String? image,
    String? url,
  }) {
    return FontItemModel(
      id: id ?? this.id,
      version: version ?? this.version,
      name: name ?? this.name,
      image: image ?? this.image,
      url: url ?? this.url,
    );
  }
}

@JsonSerializable()
class TagItemModel {
  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(defaultValue: '')
  final String name;

  TagItemModel({required this.id, required this.name});

  factory TagItemModel.fromJson(Map<String, dynamic> json) =>
      _$TagItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagItemModelToJson(this);

  TagItemModel copyWith({int? id, String? name}) {
    return TagItemModel(id: id ?? this.id, name: name ?? this.name);
  }
}
