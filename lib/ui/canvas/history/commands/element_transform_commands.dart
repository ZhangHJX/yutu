import 'package:flutter/material.dart';
import 'canvas_command.dart';
import '../../model/index.dart';

/// 调整大小命令
class ResizeElementCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final double oldWidth;
  final double oldHeight;
  final Offset oldPosition;
  final double newWidth;
  final double newHeight;
  final Offset newPosition;
  final double? oldFontSize;
  final double? newFontSize;
  final double? oldFontSpace;
  final double? newFontSpace;

  ResizeElementCommand({
    required this.boxes,
    required this.elementId,
    required this.oldWidth,
    required this.oldHeight,
    required this.oldPosition,
    required this.newWidth,
    required this.newHeight,
    required this.newPosition,
    this.oldFontSize,
    this.newFontSize,
    this.oldFontSpace,
    this.newFontSpace,
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
    if (element != null) {
      element.width = newWidth;
      element.height = newHeight;
      element.x = newPosition.dx;
      element.y = newPosition.dy;
      if (newFontSize != null && element.type == ElementType.text) {
        element.fontSize = newFontSize!;
      }
      if (newFontSpace != null && element.type == ElementType.text) {
        element.fontSpace = newFontSpace!;
      }
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      element.width = oldWidth;
      element.height = oldHeight;
      element.x = oldPosition.dx;
      element.y = oldPosition.dy;
      if (oldFontSize != null && element.type == ElementType.text) {
        element.fontSize = oldFontSize!;
      }
      if (oldFontSpace != null && element.type == ElementType.text) {
        element.fontSpace = oldFontSpace!;
      }
    }
  }

  @override
  String get description => '调整大小: $elementId';
}

/// 旋转元素命令
class RotateElementCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final double oldRotation;
  final double newRotation;

  RotateElementCommand(
    this.boxes,
    this.elementId,
    this.oldRotation,
    this.newRotation,
  );

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
    if (element != null) {
      element.rotation = newRotation;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      element.rotation = oldRotation;
    }
  }

  @override
  String get description => '旋转元素: $elementId';
}

/// 缩放元素命令（双指缩放）
class ScaleElementCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final double oldCumulativeScale;
  final double newCumulativeScale;
  final double oldWidth;
  final double oldHeight;
  final Offset oldPosition;
  final double newWidth;
  final double newHeight;
  final Offset newPosition;
  final double? oldFontSize;
  final double? newFontSize;

  ScaleElementCommand({
    required this.boxes,
    required this.elementId,
    required this.oldCumulativeScale,
    required this.newCumulativeScale,
    required this.oldWidth,
    required this.oldHeight,
    required this.oldPosition,
    required this.newWidth,
    required this.newHeight,
    required this.newPosition,
    this.oldFontSize,
    this.newFontSize,
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
    if (element != null) {
      element.scale = newCumulativeScale;
      element.width = newWidth;
      element.height = newHeight;
      element.x = newPosition.dx;
      element.y = newPosition.dy;
      if (newFontSize != null && element.type == ElementType.text) {
        element.fontSize = newFontSize!;
      }
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      element.scale = oldCumulativeScale;
      element.width = oldWidth;
      element.height = oldHeight;
      element.x = oldPosition.dx;
      element.y = oldPosition.dy;
      if (oldFontSize != null && element.type == ElementType.text) {
        element.fontSize = oldFontSize!;
      }
    }
  }

  @override
  String get description => '缩放元素: $elementId';
}
