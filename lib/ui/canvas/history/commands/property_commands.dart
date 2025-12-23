import 'package:flutter/material.dart';
import 'canvas_command.dart';
import '../../model/index.dart';

/// 更新文本内容命令
class UpdateTextCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final String oldText;
  final String newText;
  final double oldHeight;
  final double newHeight;

  UpdateTextCommand({
    required this.boxes,
    required this.elementId,
    required this.oldText,
    required this.newText,
    required this.oldHeight,
    required this.newHeight,
  });

  CanvasElement? _findElement() {
    try {
      return boxes.firstWhere((box) => box.id == elementId);
    } catch (e) {
      return null;
    }
  }

  @override
  void execute() {
    final element = _findElement();
    if (element != null && element.type == ElementType.text) {
      element.text = newText;
      element.height = newHeight;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null && element.type == ElementType.text) {
      element.text = oldText;
      element.height = oldHeight;
    }
  }

  @override
  String get description => '更新文本: $elementId';
}

/// 更新文本属性命令
class UpdateTextPropertiesCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;

  UpdateTextPropertiesCommand({
    required this.boxes,
    required this.elementId,
    required this.oldProperties,
    required this.newProperties,
  });

  CanvasElement? _findElement() {
    try {
      return boxes.firstWhere((box) => box.id == elementId);
    } catch (e) {
      return null;
    }
  }

  void _applyProperties(Map<String, dynamic> properties) {
    final element = _findElement();
    if (element == null || element.type != ElementType.text) return;

    if (properties.containsKey('fontSize')) {
      element.fontSize = properties['fontSize'] as double;
    }
    if (properties.containsKey('familyKey')) {
      element.familyKey = properties['familyKey'] as String;
    }
    if (properties.containsKey('textColor')) {
      element.textColor = properties['textColor'] as String;
    }
    if (properties.containsKey('textAlpha')) {
      element.textAlpha = properties['textAlpha'] as double;
    }
    if (properties.containsKey('lineHeight')) {
      element.lineHeight = properties['lineHeight'] as double;
    }
    if (properties.containsKey('fontSpace')) {
      element.fontSpace = properties['fontSpace'] as double;
    }
    if (properties.containsKey('align')) {
      element.align = properties['align'] as TextAlign;
    }
    if (properties.containsKey('width')) {
      element.width = properties['width'] as double;
    }
    if (properties.containsKey('height')) {
      element.height = properties['height'] as double;
    }
    if (properties.containsKey('borderColor')) {
      element.borderColor = properties['borderColor'] as String;
    }
    if (properties.containsKey('borderAlpha')) {
      element.borderAlpha = properties['borderAlpha'] as double;
    }
    if (properties.containsKey('borderWidth')) {
      element.borderWidth = properties['borderWidth'] as int;
    }
    if (properties.containsKey('isShawOpen')) {
      element.isShawOpen = properties['isShawOpen'] as bool;
    }
    if (properties.containsKey('shawColor')) {
      element.shawColor = properties['shawColor'] as String;
    }
    if (properties.containsKey('shawAlpha')) {
      element.shawAlpha = properties['shawAlpha'] as double;
    }
    if (properties.containsKey('shawX')) {
      element.shawX = properties['shawX'] as double;
    }
    if (properties.containsKey('shawY')) {
      element.shawY = properties['shawY'] as double;
    }
    if (properties.containsKey('blurValue')) {
      element.blurValue = properties['blurValue'] as double;
    }
    // 注意：不处理 position 属性，位置变更应该由 MoveElementCommand 单独处理
    // 这样可以确保撤销时按照操作顺序进行：先撤销属性变更，再撤销位置移动
  }

  @override
  void execute() {
    _applyProperties(newProperties);
  }

  @override
  void undo() {
    _applyProperties(oldProperties);
  }

  @override
  String get description => '更新文本属性: $elementId';
}

/// 更新形状属性命令
class UpdateShapePropertiesCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;

  UpdateShapePropertiesCommand({
    required this.boxes,
    required this.elementId,
    required this.oldProperties,
    required this.newProperties,
  });

  CanvasElement? _findElement() {
    try {
      return boxes.firstWhere((box) => box.id == elementId);
    } catch (e) {
      return null;
    }
  }

  void _applyProperties(Map<String, dynamic> properties) {
    final element = _findElement();
    if (element == null) return;

    if (properties.containsKey('fillColor')) {
      element.fillColor = properties['fillColor'] as String;
    }
    if (properties.containsKey('fillAlpha')) {
      element.fillAlpha = properties['fillAlpha'] as double;
    }
    if (properties.containsKey('borderColor')) {
      element.borderColor = properties['borderColor'] as String;
    }
    if (properties.containsKey('borderAlpha')) {
      element.borderAlpha = properties['borderAlpha'] as double;
    }
    if (properties.containsKey('borderWidth')) {
      element.borderWidth = properties['borderWidth'] as int;
    }
    if (properties.containsKey('isShawOpen')) {
      element.isShawOpen = properties['isShawOpen'] as bool;
    }
    if (properties.containsKey('shawColor')) {
      element.shawColor = properties['shawColor'] as String;
    }
    if (properties.containsKey('shawAlpha')) {
      element.shawAlpha = properties['shawAlpha'] as double;
    }
    if (properties.containsKey('shawX')) {
      element.shawX = properties['shawX'] as double;
    }
    if (properties.containsKey('shawY')) {
      element.shawY = properties['shawY'] as double;
    }
    if (properties.containsKey('blurValue')) {
      element.blurValue = properties['blurValue'] as double;
    }
    if (properties.containsKey('height')) {
      element.height = properties['height'] as double;
    }
  }

  @override
  void execute() {
    _applyProperties(newProperties);
  }

  @override
  void undo() {
    _applyProperties(oldProperties);
  }

  @override
  String get description => '更新形状属性: $elementId';
}

/// 更新图片属性命令
class UpdateImagePropertiesCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final double? oldWidth;
  final double? oldHeight;
  final String? oldImagePath;
  final double? oldImageAlpha;
  final double? newWidth;
  final double? newHeight;
  final String? newImagePath;
  final double? newImageAlpha;

  UpdateImagePropertiesCommand({
    required this.boxes,
    required this.elementId,
    this.oldWidth,
    this.oldHeight,
    this.oldImagePath,
    this.oldImageAlpha,
    this.newWidth,
    this.newHeight,
    this.newImagePath,
    this.newImageAlpha,
  });

  CanvasElement? _findElement() {
    try {
      return boxes.firstWhere((box) => box.id == elementId);
    } catch (e) {
      return null;
    }
  }

  @override
  void execute() {
    final element = _findElement();
    if (element != null && element.type == ElementType.image) {
      if (newWidth != null) element.width = newWidth!;
      if (newHeight != null) element.height = newHeight!;
      if (newImagePath != null) element.filePath = newImagePath!;
      if (newImageAlpha != null) element.fileAlpha = newImageAlpha!;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null && element.type == ElementType.image) {
      if (oldWidth != null) element.width = oldWidth!;
      if (oldHeight != null) element.height = oldHeight!;
      if (oldImagePath != null) element.filePath = oldImagePath!;
      if (oldImageAlpha != null) element.fileAlpha = oldImageAlpha!;
    }
  }

  @override
  String get description => '更新图片属性: $elementId';
}
