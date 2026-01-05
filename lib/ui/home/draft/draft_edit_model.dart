import 'package:json_annotation/json_annotation.dart';

part 'draft_edit_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DraftEditModel {
  final int id;
  @JsonKey(name: 'edit_time')
  final int editTime;
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

  @JsonKey(name: 'front_data', defaultValue: <DraftEditItemModel>[])
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
  @JsonKey(name: 'front_id')
  final int? frontId;

  @JsonKey(name: 'front_version')
  final String? frontVersion;

  DraftEditItemModel({this.frontId, this.frontVersion});

  factory DraftEditItemModel.fromJson(Map<String, dynamic> json) =>
      _$DraftEditItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$DraftEditItemModelToJson(this);
}
