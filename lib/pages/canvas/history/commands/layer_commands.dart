import 'canvas_command.dart';
import '../../model/index.dart';

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
