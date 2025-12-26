import 'package:json_annotation/json_annotation.dart';
part 'design_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DesignModel {
  @JsonKey(name: 'list')
  final List<DesignItemModel> items;

  DesignModel({required this.items});

  factory DesignModel.fromJson(Map<String, dynamic> json) =>
      _$DesignModelFromJson(json);

  Map<String, dynamic> toJson() => _$DesignModelToJson(this);
}

@JsonSerializable()
class DesignItemModel {
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

  DesignItemModel({
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
  });

  factory DesignItemModel.fromJson(Map<String, dynamic> json) =>
      _$DesignItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$DesignItemModelToJson(this);
}
