import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:common/common.dart';
import '../../widgets/index.dart';
import '../../history/clone_tools/edit_box_data_clone.dart';
import '../../model/index.dart';
import '../../utils/index.dart';
import 'canvals_editor_page_undo_redo_mixin.dart';
import '../../draft/index.dart';
import '../../widgets/dialog/image/canvals_image_dialog.dart';
import 'canvals_controller.dart';

/// Dialog 管理功能 Mixin
///
/// 为 CanvasEditorPage 提供所有 Dialog 显示功能
/// 使用此 mixin 的类需要：
/// 1. 使用 CanvasEditorUndoRedoMixin
/// 2. 提供以下抽象成员：
///    - setState: State 的 setState 方法
///    - deleteShape: 删除形状的方法
///    - deleteText: 删除文本的方法
///    - deleteImage: 删除图片的方法
///    - replaceImage: 替换图片的方法
///    - getCanvasCenter: 获取画布中心的方法
///    - refreshTextBoxAfterPropertyChange: 刷新文本框的方法（可选）
///    - savedTextWidth: 保存的文本宽度（可选，用于文本）
///    - lastPropertySnapshot: 上一次的属性快照（可选，用于文本）
mixin CanvasEditorDialogMixin<T extends StatefulWidget>
    on State<T>, CanvasEditorUndoRedoMixin<T> {
  /// 显示形状属性弹框
  void showShapePropertyDialog() {
    if (activeElement == null) return;

    // 初始化元素属性快照
    initElementProperties();

    SmartDialog.show(
      builder: (context) => ShapePropertyDialog(
        element: activeElement,
        onDeleteShape: () {
          deleteShape();
        },
        onPropertiesChanged: (update) {
          setState(() {});
          // 每次属性改变时立即记录命令
          if (update) {
            recordShapePropertyChange();
          }
          // 通知草稿管理器元素属性已变更
          DraftManager().notifyElementPropertyChanged();
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () {
          SmartDialog.dismiss();
        },
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示文本属性弹框
  void showTextPropertyDialog() {
    // 确保有激活的文本元素
    if (activeElement == null || activeElement!.type != ElementType.text) {
      return;
    }
    final element = activeElement!;
    // 保存打开对话框时的宽度，用于判断是否是多行状态
    savedTextWidth = element.width;

    // 初始化元素属性快照
    initElementProperties();

    // 保存上一次的属性值（用于判断是否需要重新计算尺寸）
    lastPropertySnapshot = CanvasElementClone.clone(element);

    SmartDialog.show(
      builder: (context) => TextPropertyDialog(
        element: element,
        onDeleteText: () {
          deleteText();
        },
        onPropertyChanged: (update) {
          // 属性实时更新时的回调，立即刷新UI和重新计算尺寸
          refreshTextBoxAfterPropertyChange();
          if (update) {
            recordTextPropertyChange();
            // 通知草稿管理器元素属性已变更
            DraftManager().notifyElementPropertyChanged();
          }
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () {
          SmartDialog.dismiss();
        },
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示画布属性弹框
  void showCanvalsPropertyDialog() {
    final canvasModel = canvalsController.canvasModel;

    SmartDialog.show(
      builder: (context) => CanvalsPropertyDialog(
        canvasModel: canvasModel,
        onPropertyChanged: (update) {
          setState(() {});
          // 每次属性改变时立即记录命令
          if (update) {
            recordCanvasPropertyChange();
          }
          // 通知草稿管理器画布属性已变更
          DraftManager().notifyCanvasPropertyChanged();
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示图片属性弹框
  void showImagePropertyDialog(BuildContext currentContext) {
    if (activeElement == null || activeElement!.type != ElementType.image) {
      return;
    }
    // 初始化元素属性快照
    initElementProperties();

    SmartDialog.show(
      builder: (context) => ImagePropertyDialog(
        currentContext,
        element: activeElement,
        onImageSelected: (String imagePath, double? width, double? height) {
          // 将图片添加到画布
          replaceImage(currentContext, imagePath);
        },
        onValueChanged: (update) {
          setState(() {}); // 触发界面重绘
          // 每次属性改变时立即记录命令
          if (update) {
            recordImagePropertyChange();
          }
          // 通知草稿管理器元素属性已变更
          DraftManager().notifyElementPropertyChanged();
        },
        onDeleteImage: () {
          deleteImage();
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () {
          SmartDialog.dismiss();
        },
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示形状选择弹框
  void showShapeDialog() {
    toggleLayerDialog(false);
    SmartDialog.show(
      builder: (context) => CanvalsShapeDialog(
        onShapeSelected: (type) {
          canvasKey.currentState?.addShape(type, getCanvasCenter());
          SmartDialog.dismiss();
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.transparent,
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  // 增加图片
  void addImageDialog(BuildContext canvalsContext) async {
    toggleLayerDialog(false);

    SmartDialog.show(
      builder: (context) => CanvalsImageDialog(
        canvalsContext,
        onImageSelected: (String imagePath, double? width, double? height) {
          // 将图片添加到画布
          final canvalsController = Get.find<CanvalsController>();
          canvalsController.addNewImage(
            imagePath,
            width ?? 200.0,
            height ?? 200.0,
            targetCenter: getCanvasCenter(),
          );
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.6),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示文本输入对话框
  void showTextInputDialog(BuildContext context) {
    toggleLayerDialog(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许控制高度
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => TextInputDialog(
        onConfirm: (text) {
          if (text.isEmpty) {
            return;
          }
          canvasKey.currentState?.addBox(
            type: ElementType.text,
            text: text,
            center: getCanvasCenter(),
          );
          Navigator.pop(context); // 关闭对话框
        },
      ),
    );
  }

  /// 显示保存模版弹框
  void showSaveTemplateDialog(Uint8List? canvalsImage) async {
    SmartDialog.show(
      builder: (context) =>
          CanvalsSaveTemplateDialog(canvalsImage: canvalsImage),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      clickMaskDismiss: false,
      maskColor: Colors.black,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示权限提示对话框
  void showPermissionDialog({
    required String title,
    required String subTitle,
    required String sureTitle,
    required VoidCallback sureAction,
  }) {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: title,
        subTitle: subTitle,
        sureTitle: sureTitle,
        sureAction: sureAction,
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 显示是否保存为草稿
  void showIsSaveDraftDialog(VoidCallback? sureAction) {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "保存为草稿",
        subTitle: '是否将编辑内容存到草稿？直接退\n出会丢失所有编辑信息',
        cancelTitle: "直接退出",
        sureTitle: "保存为草稿",
        cancelAction: () {
          DraftManager().deleteDraft();
          Get.back();
        },
        sureAction: sureAction,
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: true,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  // ====================== 抽象方法 ======================

  /// 删除形状
  void deleteShape();

  /// 删除文本
  void deleteText();

  /// 删除图片
  void deleteImage();

  /// 替换图片
  /// [context] BuildContext，用于显示图片选择器
  void replaceImage(BuildContext context, String filePath);

  /// 获取画布中心
  Offset getCanvasCenter();

  /// 刷新文本框，重新计算尺寸（当属性变化时）
  /// 注意：属性值已经在 TextPropertyDialog 中实时更新，这里只需要重新计算尺寸并刷新UI
  void refreshTextBoxAfterPropertyChange() {
    // 默认实现为空，如果不需要文本尺寸重新计算可以不实现
  }

  /// 保存的文本宽度（用于判断是否是多行状态）
  double? savedTextWidth;

  /// 上一次的属性快照（用于判断是否需要重新计算尺寸，仅用于文本）
  CanvasElement? lastPropertySnapshot;
}
