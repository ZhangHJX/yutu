import 'package:json_annotation/json_annotation.dart';
import '../../model/index.dart';
part 'home_model.g.dart';

@JsonSerializable(explicitToJson: true)
class HomeModel {
  @JsonKey(defaultValue: [])
  final List<TagModel> tagList;

  @JsonKey(defaultValue: [])
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
