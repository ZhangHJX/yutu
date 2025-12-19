// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasElement _$CanvasElementFromJson(Map<String, dynamic> json) =>
    CanvasElement(
      id: json['id'] as String? ?? '',
      type: $enumDecode(_$ElementTypeEnumMap, json['type']),
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      hidden: json['hidden'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
      fileName: json['fileName'] as String? ?? '',
      fileAlpha: (json['fileAlpha'] as num?)?.toDouble() ?? 1.0,
      fillAlpha: (json['fillAlpha'] as num?)?.toDouble() ?? 1.0,
      fillColor: json['fillColor'] as String? ?? '#D8D8D8',
      text: json['text'] as String? ?? '',
      fontId: (json['fontId'] as num?)?.toInt() ?? 0,
      familyKey: json['familyKey'] as String? ?? defaultConfigFamliy,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      fontWeight: (json['fontWeight'] as num?)?.toInt() ?? 400,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.0,
      fontSpace: (json['fontSpace'] as num?)?.toDouble() ?? 0,
      align: json['align'] == null
          ? TextAlign.left
          : CanvasElement._textAlignFromJson((json['align'] as num).toInt()),
      textColor: json['textColor'] as String? ?? "#000000",
      textAlpha: (json['textAlpha'] as num?)?.toDouble() ?? 1.0,
      isShawOpen: json['isShawOpen'] as bool? ?? false,
      shawColor: json['shawColor'] as String? ?? '#D8D8D8',
      shawX: (json['shawX'] as num?)?.toDouble() ?? 0,
      shawY: (json['shawY'] as num?)?.toDouble() ?? 0,
      blurValue: (json['blurValue'] as num?)?.toDouble() ?? 0,
      shawAlpha: (json['shawAlpha'] as num?)?.toDouble() ?? 1.0,
      borderColor: json['borderColor'] as String? ?? '#D8D8D8',
      borderWidth: (json['borderWidth'] as num?)?.toInt() ?? 0,
      borderAlpha: (json['borderAlpha'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$CanvasElementToJson(CanvasElement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ElementTypeEnumMap[instance.type]!,
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'hidden': instance.hidden,
      'locked': instance.locked,
      'selected': instance.selected,
      'fileName': instance.fileName,
      'fileAlpha': instance.fileAlpha,
      'fillColor': instance.fillColor,
      'fillAlpha': instance.fillAlpha,
      'text': instance.text,
      'fontSize': instance.fontSize,
      'fontId': instance.fontId,
      'familyKey': instance.familyKey,
      'fontWeight': instance.fontWeight,
      'align': CanvasElement._textAlignToJson(instance.align),
      'lineHeight': instance.lineHeight,
      'fontSpace': instance.fontSpace,
      'textColor': instance.textColor,
      'textAlpha': instance.textAlpha,
      'isShawOpen': instance.isShawOpen,
      'shawColor': instance.shawColor,
      'shawX': instance.shawX,
      'shawY': instance.shawY,
      'blurValue': instance.blurValue,
      'shawAlpha': instance.shawAlpha,
      'borderColor': instance.borderColor,
      'borderWidth': instance.borderWidth,
      'borderAlpha': instance.borderAlpha,
      'rotation': instance.rotation,
      'scale': instance.scale,
    };

const _$ElementTypeEnumMap = {
  ElementType.image: 'image',
  ElementType.rectangle: 'rectangle',
  ElementType.ellipse: 'ellipse',
  ElementType.line: 'line',
  ElementType.text: 'text',
};
