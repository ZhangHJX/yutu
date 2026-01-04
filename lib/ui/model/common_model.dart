import 'package:json_annotation/json_annotation.dart';
part 'common_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CommonModel {
  @JsonKey(name: 'list')
  final List<CommonItemModel> items;

  CommonModel({required this.items});

  factory CommonModel.fromJson(Map<String, dynamic> json) =>
      _$CommonModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommonModelToJson(this);
}

@JsonSerializable()
class CommonItemModel {
  final int? id;
  final String? uuid;
  final String? title;
  final String? desc;
  final String? canvas;
  @JsonKey(name: 'canvas_size')
  final String? canvasSize;
  @JsonKey(name: 'original_image')
  final String? originalImage;

  @JsonKey(name: 'ordinary_image')
  final String? ordinaryImage;
  final String? thumbnail;

  @JsonKey(name: 'favorite_total')
  final int? favoriteTotal;

  @JsonKey(name: 'is_favorite')
  final int? isFavorite;

  @JsonKey(name: 'is_official')
  final int? isOfficial;

  CommonItemModel({
    this.id,
    this.uuid,
    this.title,
    this.desc,
    this.canvas,
    this.canvasSize,
    this.originalImage,
    this.ordinaryImage,
    this.thumbnail,
    this.favoriteTotal,
    this.isFavorite,
    this.isOfficial,
  });

  factory CommonItemModel.fromJson(Map<String, dynamic> json) =>
      _$CommonItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$CommonItemModelToJson(this);

  CommonItemModel copyWith({
    int? id,
    String? uuid,
    String? title,
    String? desc,
    String? canvas,
    String? canvasSize,
    String? originalImage,
    String? ordinaryImage,
    String? thumbnail,
    int? favoriteTotal,
    int? isFavorite,
    int? isOfficial,
  }) {
    return CommonItemModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      canvas: canvas ?? this.canvas,
      canvasSize: canvasSize ?? this.canvasSize,
      originalImage: originalImage ?? this.originalImage,
      ordinaryImage: ordinaryImage ?? this.ordinaryImage,
      thumbnail: thumbnail ?? this.thumbnail,
      favoriteTotal: favoriteTotal ?? this.favoriteTotal,
      isFavorite: isFavorite ?? this.isFavorite,
      isOfficial: isOfficial ?? this.isOfficial,
    );
  }
}
