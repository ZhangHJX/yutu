// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignModel _$DesignModelFromJson(Map<String, dynamic> json) => DesignModel(
  items: (json['list'] as List<dynamic>)
      .map((e) => DesignItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DesignModelToJson(DesignModel instance) =>
    <String, dynamic>{'list': instance.items.map((e) => e.toJson()).toList()};

DesignItemModel _$DesignItemModelFromJson(Map<String, dynamic> json) =>
    DesignItemModel(
      id: (json['id'] as num?)?.toInt(),
      uuid: json['uuid'] as String?,
      title: json['title'] as String?,
      desc: json['desc'] as String?,
      canvas: json['canvas'] as String?,
      canvasSize: json['canvas_size'] as String?,
      originalImage: json['original_image'] as String?,
      ordinaryImage: json['ordinary_image'] as String?,
      thumbnail: json['thumbnail'] as String?,
      favoriteTotal: (json['favorite_total'] as num?)?.toInt(),
      isFavorite: (json['is_favorite'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DesignItemModelToJson(DesignItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'title': instance.title,
      'desc': instance.desc,
      'canvas': instance.canvas,
      'canvas_size': instance.canvasSize,
      'original_image': instance.originalImage,
      'ordinary_image': instance.ordinaryImage,
      'thumbnail': instance.thumbnail,
      'favorite_total': instance.favoriteTotal,
      'is_favorite': instance.isFavorite,
    };
