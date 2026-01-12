// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FontInfoModel _$FontInfoModelFromJson(Map<String, dynamic> json) =>
    FontInfoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      version: json['version'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );

Map<String, dynamic> _$FontInfoModelToJson(FontInfoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'name': instance.name,
      'image': instance.image,
      'url': instance.url,
    };
