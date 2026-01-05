// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_edit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftEditModel _$DraftEditModelFromJson(Map<String, dynamic> json) =>
    DraftEditModel(
      id: (json['id'] as num).toInt(),
      editTime: (json['edit_time'] as num).toInt(),
      canvas: json['canvas'] as String,
      canvasSize: json['canvas_size'] as String,
      originalImage: json['original_image'] as String,
      ordinaryImage: json['ordinary_image'] as String,
      thumbnail: json['thumbnail'] as String,
      recourcesUrl: json['recources_url'] as String,
      frontData:
          (json['front_data'] as List<dynamic>?)
              ?.map(
                (e) => DraftEditItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$DraftEditModelToJson(DraftEditModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'edit_time': instance.editTime,
      'canvas': instance.canvas,
      'canvas_size': instance.canvasSize,
      'original_image': instance.originalImage,
      'ordinary_image': instance.ordinaryImage,
      'thumbnail': instance.thumbnail,
      'recources_url': instance.recourcesUrl,
      'front_data': instance.frontData.map((e) => e.toJson()).toList(),
    };

DraftEditItemModel _$DraftEditItemModelFromJson(Map<String, dynamic> json) =>
    DraftEditItemModel(
      frontId: (json['front_id'] as num?)?.toInt(),
      frontVersion: json['front_version'] as String?,
    );

Map<String, dynamic> _$DraftEditItemModelToJson(DraftEditItemModel instance) =>
    <String, dynamic>{
      'front_id': instance.frontId,
      'front_version': instance.frontVersion,
    };
