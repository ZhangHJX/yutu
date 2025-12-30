// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasModel _$CanvasModelFromJson(Map<String, dynamic> json) => CanvasModel(
  id: json['id'] as String? ?? '',
  ratio: json['ratio'] as String? ?? '',
  clarity: json['clarity'] as String? ?? '0',
  isCreate: json['isCreate'] as bool? ?? false,
  x: (json['x'] as num?)?.toDouble() ?? 0.0,
  y: (json['y'] as num?)?.toDouble() ?? 0.0,
  width: (json['width'] as num?)?.toDouble() ?? 1080,
  height: (json['height'] as num?)?.toDouble() ?? 1080,
  scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
  fillColor: json['fillColor'] as String? ?? '#FFFFFF',
  fillAlpha: (json['fillAlpha'] as num?)?.toDouble() ?? 1.0,
  locked: json['locked'] as bool? ?? false,
  isSelected: json['isSelected'] as bool? ?? false,
  elements:
      (json['elements'] as List<dynamic>?)
          ?.map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  version: (json['version'] as num?)?.toDouble() ?? 1.0,
  timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CanvasModelToJson(CanvasModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ratio': instance.ratio,
      'clarity': instance.clarity,
      'isCreate': instance.isCreate,
      'x': instance.x,
      'y': instance.y,
      'scale': instance.scale,
      'width': instance.width,
      'height': instance.height,
      'fillColor': instance.fillColor,
      'fillAlpha': instance.fillAlpha,
      'locked': instance.locked,
      'isSelected': instance.isSelected,
      'version': instance.version,
      'timestamp': instance.timestamp,
      'elements': instance.elements.map((e) => e.toJson()).toList(),
    };
