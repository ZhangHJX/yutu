import 'package:json_annotation/json_annotation.dart';
import '../../model/index.dart';
part 'home_model.g.dart';

@JsonSerializable(explicitToJson: true)
class HomeModel {
  final List<TagModel> tagList;
  final List<CommonItemModel> recommendList;
  HomeModel({required this.tagList, required this.recommendList});
  factory HomeModel.fromJson(Map<String, dynamic> json) =>
      _$HomeModelFromJson(json);

  Map<String, dynamic> toJson() => _$HomeModelToJson(this);

  HomeModel copyWith({
    List<TagModel>? tagList,
    List<CommonItemModel>? recommendList,
  }) {
    return HomeModel(
      tagList: tagList ?? this.tagList,
      recommendList: recommendList ?? this.recommendList,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TagModel {
  final int id;
  final String name;

  @JsonKey(name: 'is_select')
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
