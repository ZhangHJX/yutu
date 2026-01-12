import 'package:json_annotation/json_annotation.dart';

part 'draft_edit_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DraftEditModel {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(name: 'edit_time', defaultValue: 0)
  final int editTime;

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

  @JsonKey(name: 'front_data', defaultValue: [])
  final List<DraftEditItemModel> frontData;

  DraftEditModel({
    required this.id,
    required this.editTime,
    required this.canvas,
    required this.canvasSize,
    required this.originalImage,
    required this.ordinaryImage,
    required this.thumbnail,
    required this.recourcesUrl,
    required this.frontData,
  });

  factory DraftEditModel.fromJson(Map<String, dynamic> json) =>
      _$DraftEditModelFromJson(json);
  Map<String, dynamic> toJson() => _$DraftEditModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DraftEditItemModel {
  @JsonKey(name: 'front_id', defaultValue: 0)
  final int frontId;

  @JsonKey(name: 'front_version', defaultValue: '')
  final String frontVersion;

  DraftEditItemModel({required this.frontId, required this.frontVersion});

  factory DraftEditItemModel.fromJson(Map<String, dynamic> json) =>
      _$DraftEditItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$DraftEditItemModelToJson(this);
}
