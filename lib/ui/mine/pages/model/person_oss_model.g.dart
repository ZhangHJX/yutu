// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_oss_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonOssModel _$PersonOssModelFromJson(Map<String, dynamic> json) =>
    PersonOssModel(
      signUrl: json['sign_url'] as String? ?? '',
      endpoint: json['endpoint'] as String? ?? '',
      bucket: json['bucket'] as String? ?? '',
      path: json['path'] as String? ?? '',
      file: json['file'] as String? ?? '',
      resourceId: (json['resource_id'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PersonOssModelToJson(PersonOssModel instance) =>
    <String, dynamic>{
      'sign_url': instance.signUrl,
      'endpoint': instance.endpoint,
      'bucket': instance.bucket,
      'path': instance.path,
      'file': instance.file,
      'resource_id': instance.resourceId,
    };
