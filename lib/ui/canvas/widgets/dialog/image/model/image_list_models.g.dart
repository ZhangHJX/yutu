// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_list_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageListModels _$ImageListModelsFromJson(Map<String, dynamic> json) =>
    ImageListModels(
      items: (json['list'] as List<dynamic>)
          .map((e) => ImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
    );

Map<String, dynamic> _$ImageListModelsToJson(ImageListModels instance) =>
    <String, dynamic>{
      'list': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page,
      'pageSize': instance.pageSize,
    };

ImageModel _$ImageModelFromJson(Map<String, dynamic> json) => ImageModel(
  image: json['image'] as String,
  fileSize: (json['file_size'] as String).toString(),
  width: (json['width'] as String).toString(),
  height: (json['height'] as String).toString(),
);

Map<String, dynamic> _$ImageModelToJson(ImageModel instance) =>
    <String, dynamic>{
      'image': instance.image,
      'file_size': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
    };
