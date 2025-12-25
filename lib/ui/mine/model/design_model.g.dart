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
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      canvas: json['canvas'] as String,
      canvasSize: json['canvas_size'] as String,
      originalImage: json['original_image'] as String,
      ordinaryImage: json['ordinary_image'] as String,
      thumbnail: json['thumbnail'] as String,
      favoriteTotal: (json['favorite_total'] as num).toInt(),
    );

Map<String, dynamic> _$DesignItemModelToJson(DesignItemModel instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'title': instance.title,
      'canvas': instance.canvas,
      'canvas_size': instance.canvasSize,
      'original_image': instance.originalImage,
      'ordinary_image': instance.ordinaryImage,
      'thumbnail': instance.thumbnail,
      'favorite_total': instance.favoriteTotal,
    };
