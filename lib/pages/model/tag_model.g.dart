// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagModel _$TagModelFromJson(Map<String, dynamic> json) => TagModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  name: json['name'] as String? ?? '',
  list: (json['list'] as List<dynamic>)
      .map((e) => CommonItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  isSelect: (json['is_select'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TagModelToJson(TagModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'is_select': instance.isSelect,
  'list': instance.list.map((e) => e.toJson()).toList(),
};
