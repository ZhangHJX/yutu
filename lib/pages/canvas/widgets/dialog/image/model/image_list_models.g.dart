// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_list_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageListModels _$ImageListModelsFromJson(Map<String, dynamic> json) =>
    ImageListModels(
      items:
          (json['list'] as List<dynamic>?)
              ?.map((e) => ImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$ImageListModelsToJson(ImageListModels instance) =>
    <String, dynamic>{
      'list': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page,
      'pageSize': instance.pageSize,
    };

ImageModel _$ImageModelFromJson(Map<String, dynamic> json) => ImageModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  image: json['image'] as String? ?? '',
  fileSize: json['file_size'] as String? ?? '',
  canvasSize: json['canvas_size'] as String? ?? '',
);

Map<String, dynamic> _$ImageModelToJson(ImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
      'file_size': instance.fileSize,
      'canvas_size': instance.canvasSize,
    };
