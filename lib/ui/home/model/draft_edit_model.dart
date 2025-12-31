import 'package:json_annotation/json_annotation.dart';

part 'draft_edit_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DraftEditModel {
  final int id;

  @JsonKey(name: 'edit_time')
  final int editTime;

  @JsonKey(name: 'recources_url')
  final int recourcesUrl;

  DraftEditModel({
    required this.id,
    required this.editTime,
    required this.recourcesUrl,
  });

  factory DraftEditModel.fromJson(Map<String, dynamic> json) =>
      _$DraftEditModelFromJson(json);
  Map<String, dynamic> toJson() => _$DraftEditModelToJson(this);
}
