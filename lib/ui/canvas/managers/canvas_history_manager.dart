import 'package:flutter/material.dart';
import 'package:common/common.dart';
import '../model/index.dart';

/// 命令基类
abstract class CanvasCommand {
  /// 执行命令
  void execute();

  /// 撤销命令
  void undo();

  /// 获取命令描述（用于调试）
  String get description;
}

/// 历史管理器：管理撤销/重做栈
class CanvasHistoryManager {
  final List<CanvasCommand> _undoStack = [];
  final List<CanvasCommand> _redoStack = [];
  static const int _maxHistorySize = 100;

  // 响应式状态变量
  final RxBool _canUndo = false.obs;
  final RxBool _canRedo = false.obs;

  CanvasHistoryManager() {
    // 初始化时更新状态
    _updateState();
  }

  /// 是否可以撤销（响应式）
  bool get canUndo => _canUndo.value;

  /// 是否可以撤销（响应式流）
  RxBool get canUndoStream => _canUndo;

  /// 是否可以重做（响应式）
  bool get canRedo => _canRedo.value;

  /// 是否可以重做（响应式流）
  RxBool get canRedoStream => _canRedo;

  /// 更新状态
  void _updateState() {
    _canUndo.value = _undoStack.isNotEmpty;
    _canRedo.value = _redoStack.isNotEmpty;
  }

  /// 执行命令并推入撤销栈
  void executeCommand(CanvasCommand command) {
    command.execute();
    _undoStack.add(command);
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    // 执行新命令时，清空重做栈
    _redoStack.clear();
    _updateState();
  }

  /// 撤销操作
  void undo() {
    if (!_canUndo.value) return;
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    _updateState();
  }

  /// 重做操作
  void redo() {
    if (!_canRedo.value) return;
    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
    _updateState();
  }

  /// 清空历史记录
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _updateState();
  }
}

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
      element.position = newPosition;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      element.position = oldPosition;
    }
  }

  @override
  String get description => '移动元素: $elementId';
}

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
      element.position = newPosition;
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
      element.position = oldPosition;
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
      // element.rotation = newRotation;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      // element.rotation = oldRotation;
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
      // element.cumulativeScale = newCumulativeScale;
      element.width = newWidth;
      element.height = newHeight;
      element.position = newPosition;
      if (newFontSize != null && element.type == ElementType.text) {
        element.fontSize = newFontSize!;
      }
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      // element.cumulativeScale = oldCumulativeScale;
      element.width = oldWidth;
      element.height = oldHeight;
      element.position = oldPosition;
      if (oldFontSize != null && element.type == ElementType.text) {
        element.fontSize = oldFontSize!;
      }
    }
  }

  @override
  String get description => '缩放元素: $elementId';
}

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
    if (properties.containsKey('fontFamily')) {
      element.fontFamily = properties['fontFamily'] as String;
    }
    if (properties.containsKey('fontWeight')) {
      element.fontWeight = properties['fontWeight'] as FontWeight;
    }
    if (properties.containsKey('textColor')) {
      element.textColor = properties['textColor'] as String;
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
    if (properties.containsKey('position')) {
      element.position = properties['position'] as Offset;
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
    if (properties.containsKey('borderColor')) {
      element.borderColor = properties['borderColor'] as String;
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
  final double? newWidth;
  final double? newHeight;
  final String? newImagePath;

  UpdateImagePropertiesCommand({
    required this.boxes,
    required this.elementId,
    this.oldWidth,
    this.oldHeight,
    this.oldImagePath,
    this.newWidth,
    this.newHeight,
    this.newImagePath,
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
      if (newImagePath != null) element.imagePath = newImagePath!;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null && element.type == ElementType.image) {
      if (oldWidth != null) element.width = oldWidth!;
      if (oldHeight != null) element.height = oldHeight!;
      if (oldImagePath != null) element.imagePath = oldImagePath!;
    }
  }

  @override
  String get description => '更新图片属性: $elementId';
}

/// 重新排序图层命令
class ReorderLayersCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final List<String> oldOrder; // 按ID列表表示旧顺序
  final List<String> newOrder; // 按ID列表表示新顺序

  ReorderLayersCommand({
    required this.boxes,
    required this.oldOrder,
    required this.newOrder,
  });

  void _applyOrder(List<String> order) {
    // 按照指定顺序重新排列boxes
    // 如果boxes为空，直接返回（避免在撤销时出现错误）
    if (boxes.isEmpty) {
      return;
    }

    final Map<String, CanvasElement> elementMap = {
      for (var box in boxes) box.id: box,
    };

    boxes.clear();
    for (var id in order) {
      final element = elementMap[id];
      if (element != null) {
        boxes.add(element);
      }
    }
  }

  @override
  void execute() {
    _applyOrder(newOrder);
  }

  @override
  void undo() {
    _applyOrder(oldOrder);
  }

  @override
  String get description => '重新排序图层';
}

/// 切换可见性命令
class ToggleVisibilityCommand implements CanvasCommand {
  final List<CanvasElement> boxes;
  final String elementId;
  final bool oldVisible;
  final bool newVisible;

  ToggleVisibilityCommand({
    required this.boxes,
    required this.elementId,
    required this.oldVisible,
    required this.newVisible,
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
      element.hidden = newVisible;
    }
  }

  @override
  void undo() {
    final element = _findElement();
    if (element != null) {
      element.hidden = oldVisible;
    }
  }

  @override
  String get description => '切换可见性: $elementId';
}
