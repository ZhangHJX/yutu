import 'package:flutter/material.dart';
import '../../history/index.dart';
import '../../model/index.dart';
import 'widgets/canvals_editor_widget.dart';
import 'canvals_controller.dart';

/// 撤销/重做功能 Mixin
///
/// 为 CanvasEditorPage 提供撤销/重做功能
/// 使用此 mixin 的类需要提供以下成员：
/// - canvalsController: CanvalsController 实例
/// - canvasKey: GlobalKey<CanvasEditorWidgetState> 实例
/// - toggleLayerDialog: 用于关闭图层对话框的方法
mixin CanvasEditorUndoRedoMixin<T extends StatefulWidget> on State<T> {
  /// 历史管理器实例
  late final CanvasHistoryManager historyManager = CanvasHistoryManager();

  /// 用于保存上一次的元素属性值（用于判断是否需要记录命令）
  CanvasElement? lastElementProperties;

  /// 用于保存上一次的画布属性值（用于判断是否需要记录命令）
  Map<String, dynamic>? lastCanvasProperties;

  /// 获取 CanvalsController 实例
  CanvalsController get canvalsController;

  /// 获取 CanvasEditorWidget 的 GlobalKey
  GlobalKey<CanvasEditorWidgetState> get canvasKey;

  /// 关闭图层对话框的方法
  void toggleLayerDialog(bool isLayer);

  /// 获取当前激活的元素
  CanvasElement? get activeElement {
    final selectedId = canvalsController.selectedId;
    if (selectedId.isEmpty) return null;

    final layers = canvalsController.elements;
    try {
      return layers.firstWhere((layer) => layer.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  /// 初始化撤销/重做功能
  /// 应在 initState 中调用
  void initUndoRedo() {
    // 设置撤销/重做时的回调：取消元素选中状态
    historyManager.onUndoRedo = () {
      canvalsController.deselect();
    };
  }

  /// 初始化画布属性快照
  /// 应在 initState 中调用，用于记录画布属性的初始状态
  void initCanvasProperties() {
    final canvasModel = canvalsController.canvasModel;
    lastCanvasProperties = {
      'fillColor': canvasModel.fillColor,
      'fillAlpha': canvasModel.fillAlpha,
      'locked': canvasModel.locked,
    };
  }

  /// 初始化元素属性快照
  /// 应在显示属性对话框时调用
  void initElementProperties() {
    if (activeElement != null) {
      lastElementProperties = CanvasElementClone.clone(activeElement!);
    }
  }

  /// 更新元素属性快照
  /// 应在属性变更后调用
  void updateElementProperties() {
    if (activeElement != null) {
      lastElementProperties = CanvasElementClone.clone(activeElement!);
    }
  }

  /// 记录画布属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void recordCanvasPropertyChange() {
    if (lastCanvasProperties == null) return;

    final canvasModel = canvalsController.canvasModel;
    final last = lastCanvasProperties!;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (last['fillColor'] != canvasModel.fillColor) {
      historyManager.executeCommand(
        UpdateCanvasPropertiesCommand(
          canvasModel: canvasModel,
          oldProperties: {'fillColor': last['fillColor']},
          newProperties: {'fillColor': canvasModel.fillColor},
        ),
      );
    }

    if (last['fillAlpha'] != canvasModel.fillAlpha) {
      historyManager.executeCommand(
        UpdateCanvasPropertiesCommand(
          canvasModel: canvasModel,
          oldProperties: {'fillAlpha': last['fillAlpha']},
          newProperties: {'fillAlpha': canvasModel.fillAlpha},
        ),
      );
    }

    // 更新上一次的属性值（保持所有属性的同步）
    lastCanvasProperties = {
      'fillColor': canvasModel.fillColor,
      'fillAlpha': canvasModel.fillAlpha,
      'locked': canvasModel.locked, // 同步当前锁定状态
    };
  }

  /// 更新画布属性快照（用于锁定状态等直接变更的情况）
  /// [property] 要更新的属性名
  /// [value] 新的属性值
  void updateLastCanvasProperty(String property, dynamic value) {
    if (lastCanvasProperties != null) {
      lastCanvasProperties![property] = value;
    }
  }

  /// 记录形状属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void recordShapePropertyChange() {
    if (activeElement == null || lastElementProperties == null) return;

    final current = activeElement!;
    final old = lastElementProperties!;
    final boxes = canvalsController.elements;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (old.fillColor != current.fillColor) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fillColor': old.fillColor},
          newProperties: {'fillColor': current.fillColor},
        ),
      );
    }

    if (old.fillAlpha != current.fillAlpha) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fillAlpha': old.fillAlpha},
          newProperties: {'fillAlpha': current.fillAlpha},
        ),
      );
    }

    if (old.borderColor != current.borderColor) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderColor': old.borderColor},
          newProperties: {'borderColor': current.borderColor},
        ),
      );
    }

    if (old.borderAlpha != current.borderAlpha) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderAlpha': old.borderAlpha},
          newProperties: {'borderAlpha': current.borderAlpha},
        ),
      );
    }

    if (old.borderWidth != current.borderWidth) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderWidth': old.borderWidth},
          newProperties: {'borderWidth': current.borderWidth},
        ),
      );
    }

    if (old.isShawOpen != current.isShawOpen) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'isShawOpen': old.isShawOpen},
          newProperties: {'isShawOpen': current.isShawOpen},
        ),
      );
    }

    if (old.shawColor != current.shawColor) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawColor': old.shawColor},
          newProperties: {'shawColor': current.shawColor},
        ),
      );
    }

    if (old.shawAlpha != current.shawAlpha) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawAlpha': old.shawAlpha},
          newProperties: {'shawAlpha': current.shawAlpha},
        ),
      );
    }

    if (old.shawX != current.shawX) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawX': old.shawX},
          newProperties: {'shawX': current.shawX},
        ),
      );
    }

    if (old.shawY != current.shawY) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawY': old.shawY},
          newProperties: {'shawY': current.shawY},
        ),
      );
    }

    if (old.blurValue != current.blurValue) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'blurValue': old.blurValue},
          newProperties: {'blurValue': current.blurValue},
        ),
      );
    }

    if (old.height != current.height) {
      historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'height': old.height},
          newProperties: {'height': current.height},
        ),
      );
    }

    // 更新上一次的属性值
    updateElementProperties();
  }

  /// 记录文本属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void recordTextPropertyChange() {
    if (activeElement == null ||
        activeElement!.type != ElementType.text ||
        lastElementProperties == null) {
      return;
    }

    final current = activeElement!;
    final old = lastElementProperties!;
    final boxes = canvalsController.elements;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (old.fontSize != current.fontSize) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fontSize': old.fontSize},
          newProperties: {'fontSize': current.fontSize},
        ),
      );
    }

    if (old.familyKey != current.familyKey) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'familyKey': old.familyKey},
          newProperties: {'familyKey': current.familyKey},
        ),
      );
    }

    if (old.textColor != current.textColor) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'textColor': old.textColor},
          newProperties: {'textColor': current.textColor},
        ),
      );
    }

    if (old.textAlpha != current.textAlpha) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'textAlpha': old.textAlpha},
          newProperties: {'textAlpha': current.textAlpha},
        ),
      );
    }

    if (old.lineHeight != current.lineHeight) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'lineHeight': old.lineHeight},
          newProperties: {'lineHeight': current.lineHeight},
        ),
      );
    }

    if (old.fontSpace != current.fontSpace) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fontSpace': old.fontSpace},
          newProperties: {'fontSpace': current.fontSpace},
        ),
      );
    }

    if (old.align != current.align) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'align': old.align},
          newProperties: {'align': current.align},
        ),
      );
    }

    if (old.width != current.width) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'width': old.width},
          newProperties: {'width': current.width},
        ),
      );
    }

    if (old.height != current.height) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'height': old.height},
          newProperties: {'height': current.height},
        ),
      );
    }

    if (old.borderColor != current.borderColor) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderColor': old.borderColor},
          newProperties: {'borderColor': current.borderColor},
        ),
      );
    }

    if (old.borderAlpha != current.borderAlpha) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderAlpha': old.borderAlpha},
          newProperties: {'borderAlpha': current.borderAlpha},
        ),
      );
    }

    if (old.borderWidth != current.borderWidth) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderWidth': old.borderWidth},
          newProperties: {'borderWidth': current.borderWidth},
        ),
      );
    }

    if (old.isShawOpen != current.isShawOpen) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'isShawOpen': old.isShawOpen},
          newProperties: {'isShawOpen': current.isShawOpen},
        ),
      );
    }

    if (old.shawColor != current.shawColor) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawColor': old.shawColor},
          newProperties: {'shawColor': current.shawColor},
        ),
      );
    }

    if (old.shawAlpha != current.shawAlpha) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawAlpha': old.shawAlpha},
          newProperties: {'shawAlpha': current.shawAlpha},
        ),
      );
    }

    if (old.shawX != current.shawX) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawX': old.shawX},
          newProperties: {'shawX': current.shawX},
        ),
      );
    }

    if (old.shawY != current.shawY) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawY': old.shawY},
          newProperties: {'shawY': current.shawY},
        ),
      );
    }

    if (old.blurValue != current.blurValue) {
      historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'blurValue': old.blurValue},
          newProperties: {'blurValue': current.blurValue},
        ),
      );
    }

    // 更新上一次的属性值
    updateElementProperties();
  }

  /// 记录图片属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void recordImagePropertyChange() {
    if (activeElement == null ||
        activeElement!.type != ElementType.image ||
        lastElementProperties == null) {
      return;
    }

    final current = activeElement!;
    final old = lastElementProperties!;
    final boxes = canvalsController.elements;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (old.width != current.width) {
      historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: old.width,
          oldHeight: null,
          oldImagePath: null,
          newWidth: current.width,
          newHeight: null,
          newImagePath: null,
        ),
      );
    }

    if (old.height != current.height) {
      historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: null,
          oldHeight: old.height,
          oldImagePath: null,
          newWidth: null,
          newHeight: current.height,
          newImagePath: null,
        ),
      );
    }

    if (old.filePath != current.filePath) {
      historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: null,
          oldHeight: null,
          oldImagePath: old.filePath,
          newWidth: null,
          newHeight: null,
          newImagePath: current.filePath,
        ),
      );
    }

    if (old.fileAlpha != current.fileAlpha) {
      historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: null,
          oldHeight: null,
          oldImagePath: null,
          newWidth: null,
          newHeight: null,
          newImagePath: null,
          oldImageAlpha: old.fileAlpha,
          newImageAlpha: current.fileAlpha,
        ),
      );
    }

    // 更新上一次的属性值
    updateElementProperties();
  }

  /// 撤销操作
  void handleUndo() {
    debugPrint("---handleUndo--");
    toggleLayerDialog(false);
    canvasKey.currentState?.undo();
  }

  /// 重做操作
  void handleRedo() {
    toggleLayerDialog(false);
    canvasKey.currentState?.redo();
  }

  /// 是否可以撤销
  bool get canUndo => historyManager.canUndo;

  /// 是否可以重做
  bool get canRedo => historyManager.canRedo;
}
