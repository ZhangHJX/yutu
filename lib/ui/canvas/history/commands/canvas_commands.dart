import 'canvas_command.dart';
import '../../model/index.dart';

/// 更新画布属性命令
///
/// 用于记录画布属性（如填充颜色、透明度、锁定状态等）的变更
/// 支持撤销/重做功能
/// 注意：不记录画布宽高（width、height）属性的变更
class UpdateCanvasPropertiesCommand implements CanvasCommand {
  final CanvasModel canvasModel;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;

  UpdateCanvasPropertiesCommand({
    required this.canvasModel,
    required this.oldProperties,
    required this.newProperties,
  });

  void _applyProperties(Map<String, dynamic> properties) {
    if (properties.containsKey('fillColor')) {
      canvasModel.fillColor = properties['fillColor'] as String;
    }
    if (properties.containsKey('fillAlpha')) {
      canvasModel.fillAlpha = properties['fillAlpha'] as double;
    }
    if (properties.containsKey('locked')) {
      canvasModel.locked = properties['locked'] as bool;
    }
    // 注意：不处理 width 和 height 属性，这些属性不应该通过撤销/重做来恢复
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
  String get description => '更新画布属性';
}
