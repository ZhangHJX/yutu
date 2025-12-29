// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockModel _$StockModelFromJson(Map<String, dynamic> json) => StockModel(
  items: (json['list'] as List<dynamic>)
      .map((e) => StockItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StockModelToJson(StockModel instance) =>
    <String, dynamic>{'list': instance.items.map((e) => e.toJson()).toList()};

StockItemModel _$StockItemModelFromJson(Map<String, dynamic> json) =>
    StockItemModel(
      id: (json['id'] as num?)?.toInt(),
      image: json['image'] as String?,
      fileSize: json['file_size'] as String?,
      canvasSize: json['canvas_size'] as String?,
    );

Map<String, dynamic> _$StockItemModelToJson(StockItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image': instance.image,
      'file_size': instance.fileSize,
      'canvas_size': instance.canvasSize,
    };
