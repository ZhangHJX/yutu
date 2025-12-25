import 'package:common/common.dart';
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
  final String uuid;
  final String title;
  final String canvas;
  @JsonKey(name: 'canvas_size')
  final String canvasSize;
  @JsonKey(name: 'original_image')
  final String originalImage;

  @JsonKey(name: 'ordinary_image')
  final String ordinaryImage;
  final String thumbnail;

  @JsonKey(name: 'favorite_total')
  final int favoriteTotal;
  DesignItemModel({
    required this.uuid,
    required this.title,
    required this.canvas,
    required this.canvasSize,
    required this.originalImage,
    required this.ordinaryImage,
    required this.thumbnail,
    required this.favoriteTotal,
  });

  factory DesignItemModel.fromJson(Map<String, dynamic> json) =>
      _$DesignItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$DesignItemModelToJson(this);
}
