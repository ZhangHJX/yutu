// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScreenModel _$ScreenModelFromJson(Map<String, dynamic> json) => ScreenModel(
  items: (json['list'] as List<dynamic>)
      .map((e) => ScreenItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ScreenModelToJson(ScreenModel instance) =>
    <String, dynamic>{'list': instance.items.map((e) => e.toJson()).toList()};

ScreenItemModel _$ScreenItemModelFromJson(Map<String, dynamic> json) =>
    ScreenItemModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$ScreenItemModelToJson(ScreenItemModel instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
