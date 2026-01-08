// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'middle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiddleModel _$MiddleModelFromJson(Map<String, dynamic> json) => MiddleModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  editTime: (json['edit_time'] as num?)?.toInt() ?? 0,
  title: json['title'] as String? ?? '',
  desc: json['desc'] as String? ?? '',
  canvas: json['canvas'] as String? ?? '',
  canvasSize: json['canvas_size'] as String? ?? '',
  originalImage: json['original_image'] as String? ?? '',
  ordinaryImage: json['ordinary_image'] as String? ?? '',
  thumbnail: json['thumbnail'] as String? ?? '',
  recourcesUrl: json['recources_url'] as String? ?? '',
  favoriteTotal: (json['favorite_total'] as num?)?.toInt() ?? 0,
  isOfficial: (json['is_official'] as num?)?.toInt() ?? 0,
  isFavorite: (json['is_favorite'] as num?)?.toInt() ?? 0,
  frontData:
      (json['front_data'] as List<dynamic>?)
          ?.map((e) => FontItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tagData:
      (json['tag_data'] as List<dynamic>?)
          ?.map((e) => TagItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  isOwn: (json['is_own'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MiddleModelToJson(MiddleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'edit_time': instance.editTime,
      'title': instance.title,
      'desc': instance.desc,
      'canvas': instance.canvas,
      'canvas_size': instance.canvasSize,
      'original_image': instance.originalImage,
      'ordinary_image': instance.ordinaryImage,
      'thumbnail': instance.thumbnail,
      'recources_url': instance.recourcesUrl,
      'favorite_total': instance.favoriteTotal,
      'is_official': instance.isOfficial,
      'is_favorite': instance.isFavorite,
      'front_data': instance.frontData.map((e) => e.toJson()).toList(),
      'tag_data': instance.tagData.map((e) => e.toJson()).toList(),
      'is_own': instance.isOwn,
    };

FontItemModel _$FontItemModelFromJson(Map<String, dynamic> json) =>
    FontItemModel(
      frontId: (json['front_id'] as num?)?.toInt() ?? 0,
      frontVersion: json['front_version'] as String? ?? '',
      frontUrl: json['front_url'] as String? ?? '',
    );

Map<String, dynamic> _$FontItemModelToJson(FontItemModel instance) =>
    <String, dynamic>{
      'front_id': instance.frontId,
      'front_version': instance.frontVersion,
      'front_url': instance.frontUrl,
    };

TagItemModel _$TagItemModelFromJson(Map<String, dynamic> json) => TagItemModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$TagItemModelToJson(TagItemModel instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
