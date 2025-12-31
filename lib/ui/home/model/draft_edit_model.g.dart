// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_edit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftEditModel _$DraftEditModelFromJson(Map<String, dynamic> json) =>
    DraftEditModel(
      id: (json['id'] as num).toInt(),
      editTime: (json['edit_time'] as num).toInt(),
      recourcesUrl: (json['recources_url'] as num).toInt(),
    );

Map<String, dynamic> _$DraftEditModelToJson(DraftEditModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'edit_time': instance.editTime,
      'recources_url': instance.recourcesUrl,
    };
