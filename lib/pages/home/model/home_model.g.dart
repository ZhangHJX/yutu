// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeModel _$HomeModelFromJson(Map<String, dynamic> json) => HomeModel(
  tagList:
      (json['tagList'] as List<dynamic>?)
          ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  recommendList:
      (json['recommendList'] as List<dynamic>?)
          ?.map((e) => CommonItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$HomeModelToJson(HomeModel instance) => <String, dynamic>{
  'tagList': instance.tagList.map((e) => e.toJson()).toList(),
  'recommendList': instance.recommendList.map((e) => e.toJson()).toList(),
};
