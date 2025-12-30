// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeModel _$HomeModelFromJson(Map<String, dynamic> json) => HomeModel(
  tagList: (json['tagList'] as List<dynamic>)
      .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommendList: (json['recommendList'] as List<dynamic>)
      .map((e) => CommonItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$HomeModelToJson(HomeModel instance) => <String, dynamic>{
  'tagList': instance.tagList.map((e) => e.toJson()).toList(),
  'recommendList': instance.recommendList.map((e) => e.toJson()).toList(),
};

TagModel _$TagModelFromJson(Map<String, dynamic> json) => TagModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  list: (json['list'] as List<dynamic>)
      .map((e) => CommonItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  isSelect: (json['is_select'] as num).toInt(),
);

Map<String, dynamic> _$TagModelToJson(TagModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'is_select': instance.isSelect,
  'list': instance.list.map((e) => e.toJson()).toList(),
};
