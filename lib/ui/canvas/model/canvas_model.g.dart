// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasModel _$CanvasModelFromJson(Map<String, dynamic> json) => CanvasModel(
  id: json['id'] as String? ?? '',
  x: (json['x'] as num?)?.toDouble() ?? 0.0,
  y: (json['y'] as num?)?.toDouble() ?? 0.0,
  scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
  width: (json['width'] as num?)?.toDouble() ?? 1080,
  height: (json['height'] as num?)?.toDouble() ?? 1080,
  fillColor: json['fillColor'] as String? ?? '#FFFFFF',
  fillAlpha: (json['fillAlpha'] as num?)?.toDouble() ?? 1.0,
  borderColor: json['borderColor'] as String? ?? '#BFBFBF',
  borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0,
  borderAlpha: (json['borderAlpha'] as num?)?.toDouble() ?? 1.0,
  locked: json['locked'] as bool? ?? true,
  isSelected: json['isSelected'] as bool? ?? false,
);

Map<String, dynamic> _$CanvasModelToJson(CanvasModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'x': instance.x,
      'y': instance.y,
      'scale': instance.scale,
      'width': instance.width,
      'height': instance.height,
      'fillColor': instance.fillColor,
      'fillAlpha': instance.fillAlpha,
      'borderColor': instance.borderColor,
      'borderWidth': instance.borderWidth,
      'borderAlpha': instance.borderAlpha,
      'locked': instance.locked,
      'isSelected': instance.isSelected,
    };
