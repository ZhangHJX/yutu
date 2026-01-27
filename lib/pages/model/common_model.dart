import 'package:json_annotation/json_annotation.dart';
part 'common_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CommonModel {
  @JsonKey(name: 'list', defaultValue: [])
  final List<CommonItemModel> items;

  CommonModel({required this.items});

  factory CommonModel.fromJson(Map<String, dynamic> json) =>
      _$CommonModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommonModelToJson(this);
}

@JsonSerializable()
class CommonItemModel {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: '')
  final String uuid;

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

  @JsonKey(name: 'favorite_total', defaultValue: 0)
  final int favoriteTotal;

  @JsonKey(name: 'is_favorite', defaultValue: 0)
  final int isFavorite;

  @JsonKey(name: 'is_official', defaultValue: 0)
  final int isOfficial;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isSelected;

  CommonItemModel({
    required this.id,
    required this.uuid,
    required this.title,
    required this.desc,
    required this.canvas,
    required this.canvasSize,
    required this.originalImage,
    required this.ordinaryImage,
    required this.thumbnail,
    required this.favoriteTotal,
    required this.isFavorite,
    required this.isOfficial,
    this.isSelected = false,
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
    bool? isSelected,
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
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
