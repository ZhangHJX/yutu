import 'package:json_annotation/json_annotation.dart';
import 'common_model.dart';

part 'tag_model.g.dart';

@JsonSerializable(explicitToJson: true)
class TagModel {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(name: 'is_select', defaultValue: 0)
  final int isSelect;

  final List<CommonItemModel> list;

  TagModel({
    required this.id,
    required this.name,
    required this.list,
    required this.isSelect,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagModelToJson(this);

  TagModel copyWith({
    int? id,
    String? name,
    int? isSelect,
    List<CommonItemModel>? list,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelect: isSelect ?? this.isSelect,
      list: list ?? this.list,
    );
  }
}
