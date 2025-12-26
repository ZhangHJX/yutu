import 'package:json_annotation/json_annotation.dart';
part 'screen_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ScreenModel {
  @JsonKey(name: 'list')
  final List<ScreenItemModel> items;

  ScreenModel({required this.items});

  factory ScreenModel.fromJson(Map<String, dynamic> json) =>
      _$ScreenModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenModelToJson(this);
}

@JsonSerializable()
class ScreenItemModel {
  final int id;
  final String name;
  ScreenItemModel({required this.id, required this.name});

  factory ScreenItemModel.fromJson(Map<String, dynamic> json) =>
      _$ScreenItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$ScreenItemModelToJson(this);
}
