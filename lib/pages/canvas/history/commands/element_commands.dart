import 'package:flutter/material.dart';
import 'canvas_command.dart';
import '../../model/index.dart';

/// 添加元素命令
class AddElementCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final CanvasElement element;

  AddElementCommand(this.boxes, this.element);

  @override
  void execute() {
    // 检查元素是否已存在，避免重复添加（用于重做场景）
    if (!boxes.any((box) => box.id == element.id)) {
      boxes.add(element);
    }
  }

  @override
  void undo() {
    boxes.removeWhere((box) => box.id == element.id);
  }

  @override
  String get description => '添加元素: ${element.id}';
}

/// 删除元素命令
class DeleteElementCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final CanvasElement element;
  final int originalIndex;

  DeleteElementCommand(this.boxes, this.element)
    : originalIndex = boxes.indexOf(element);

  @override
  void execute() {
    // 检查元素是否存在，避免重复删除（用于重做场景）
    if (boxes.any((box) => box.id == element.id)) {
      boxes.removeWhere((box) => box.id == element.id);
    }
  }

  @override
  void undo() {
    // 检查元素是否已存在，避免重复添加（用于撤销场景）
    if (!boxes.any((box) => box.id == element.id)) {
      // 恢复到原来的位置
      if (originalIndex >= 0 && originalIndex <= boxes.length) {
        boxes.insert(originalIndex, element);
      } else {
        boxes.add(element);
      }
    }
  }

  @override
  String get description => '删除元素: ${element.id}';
}

/// 移动元素命令
class MoveElementCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final Offset oldPosition;
  final Offset newPosition;

  MoveElementCommand(
    this.boxes,
    this.elementId,
    this.oldPosition,
    this.newPosition,
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
      element.x = newPosition.dx;
      element.y = newPosition.dy;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      element.x = oldPosition.dx;
      element.y = oldPosition.dy;
    }
  }

  @override
  String get description => '移动元素: $elementId';
}
