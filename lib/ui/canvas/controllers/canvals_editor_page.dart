import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../widgets/canvas_app_bar_widget.dart';
import '../widgets/canvas_bottom_bar_widget.dart';
import '../widgets/canvas_control_widget.dart';
import '../widgets/dialog/canvals_layer_dialog.dart';
import '../widgets/dialog/canvals_save_dialog.dart';
import '../widgets/property/element_attribute_toolbar.dart';
import '../widgets/property/canvals_property_dialog.dart';
import '../widgets/property/image_property_dialog.dart';
import '../widgets/property/shape_property_dialog.dart';
import '../widgets/property/text_property_dialog.dart';
import '../widgets/dialog/text_input_dialog.dart';
import '../widgets/dialog/canvals_shape_dialog.dart';
import '../canvals/canvals_editor_widget.dart';
import 'canvals_controller.dart';
import '../utils/text_measure_util.dart';
import 'package:screenshot/screenshot.dart';
import '../history/index.dart';
import '../gesture/canvas_status_manager.dart';
import '../utils/index.dart';
import '../model/index.dart';
import '../canvals/transform_canvas.dart';

import '../gesture/canvas_pointer_wrapper.dart';
part './editor_extension/canvals_editor_page_dialog.dart';

class CanvasEditorPage extends StatefulWidget {
  const CanvasEditorPage({super.key});
  @override
  State<CanvasEditorPage> createState() => _CanvasEditorPagePageState();
}

class _CanvasEditorPagePageState extends State<CanvasEditorPage> {
  final CanvalsController _canvalsController = Get.put(CanvalsController());
  final ScreenshotController _screenshotController = ScreenshotController();
  final CanvasHistoryManager _historyManager = CanvasHistoryManager();

  final GlobalKey<CanvasEditorWidgetState> _canvasKey =
      GlobalKey<CanvasEditorWidgetState>();
  final GlobalKey _canvasContainerKey = GlobalKey();
  bool _showLayerDialog = false; // 添加图层弹框显示状态
  double? _savedTextWidth; // 保存打开文本属性对话框时的宽度

  // 用于保存上一次的元素属性值（用于判断是否需要记录命令）
  CanvasElement? _lastElementProperties;
  // 用于保存上一次的属性值（用于判断是否需要重新计算尺寸，仅用于文本）
  CanvasElement? _lastPropertySnapshot;
  // 用于保存上一次的画布属性值（用于判断是否需要记录命令）
  Map<String, dynamic>? _lastCanvasProperties;
  // 画布手势管理器
  final _canvasStatusManager = CanvasStatusManager();

  @override
  void initState() {
    super.initState();
    // 监听画布变换变化（统一写回 CanvasModel）
    _canvasStatusManager.onMatrixChanged = (matrix, scale, offset) {
      if (!mounted) return;
      setState(() {
        _canvalsController.canvasModel.updateMatrix4(matrix, scale, offset);
      });
    };
    _canvasStatusManager.matrix = _canvalsController.canvasModel.transform;
    // 设置撤销/重做时的回调：取消元素选中状态
    _historyManager.onUndoRedo = () {
      _canvalsController.deselect();
    };

    // 初始化上一次的画布属性值
    final canvasModel = _canvalsController.canvasModel;
    _lastCanvasProperties = {
      'fillColor': canvasModel.fillColor,
      'fillAlpha': canvasModel.fillAlpha,
      'locked': canvasModel.locked,
    };
  }

  /// 显示形状属性弹框
  void _showShapePropertyDialog() {
    if (_activeElement == null) return;

    // 初始化上一次的属性值
    _lastElementProperties = CanvasElementClone.clone(_activeElement!);

    SmartDialog.show(
      builder: (context) => ShapePropertyDialog(
        element: _activeElement,
        onDeleteShape: () {
          _deleteShape();
        },
        onPropertiesChanged: (update) {
          setState(() {});
          // 每次属性改变时立即记录命令
          if (update) {
            _recordShapePropertyChange();
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

  /// 记录形状属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void _recordShapePropertyChange() {
    if (_activeElement == null || _lastElementProperties == null) return;

    final current = _activeElement!;
    final old = _lastElementProperties!;
    final boxes = _canvalsController.elements;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (old.fillColor != current.fillColor) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fillColor': old.fillColor},
          newProperties: {'fillColor': current.fillColor},
        ),
      );
    }

    if (old.fillAlpha != current.fillAlpha) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fillAlpha': old.fillAlpha},
          newProperties: {'fillAlpha': current.fillAlpha},
        ),
      );
    }

    if (old.borderColor != current.borderColor) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderColor': old.borderColor},
          newProperties: {'borderColor': current.borderColor},
        ),
      );
    }

    if (old.borderAlpha != current.borderAlpha) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderAlpha': old.borderAlpha},
          newProperties: {'borderAlpha': current.borderAlpha},
        ),
      );
    }

    if (old.borderWidth != current.borderWidth) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderWidth': old.borderWidth},
          newProperties: {'borderWidth': current.borderWidth},
        ),
      );
    }

    if (old.isShawOpen != current.isShawOpen) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'isShawOpen': old.isShawOpen},
          newProperties: {'isShawOpen': current.isShawOpen},
        ),
      );
    }

    if (old.shawColor != current.shawColor) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawColor': old.shawColor},
          newProperties: {'shawColor': current.shawColor},
        ),
      );
    }

    if (old.shawAlpha != current.shawAlpha) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawAlpha': old.shawAlpha},
          newProperties: {'shawAlpha': current.shawAlpha},
        ),
      );
    }

    if (old.shawX != current.shawX) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawX': old.shawX},
          newProperties: {'shawX': current.shawX},
        ),
      );
    }

    if (old.shawY != current.shawY) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawY': old.shawY},
          newProperties: {'shawY': current.shawY},
        ),
      );
    }

    if (old.blurValue != current.blurValue) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'blurValue': old.blurValue},
          newProperties: {'blurValue': current.blurValue},
        ),
      );
    }

    if (old.height != current.height) {
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'height': old.height},
          newProperties: {'height': current.height},
        ),
      );
    }

    // 更新上一次的属性值
    _lastElementProperties = CanvasElementClone.clone(current);
  }

  /// 删除形状
  void _deleteShape() {
    if (_activeElement != null) {
      debugPrint('删除形状');
      _canvasKey.currentState?.deleteBox(_activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 显示文本属性弹框
  void _showTextPropertyDialog() {
    // 确保有激活的文本元素
    if (_activeElement == null || _activeElement!.type != ElementType.text) {
      return;
    }
    final activeElement = _activeElement!;
    // 保存打开对话框时的宽度，用于判断是否是多行状态
    _savedTextWidth = activeElement.width;

    // 初始化上一次的属性值
    _lastElementProperties = CanvasElementClone.clone(activeElement);

    // 保存上一次的属性值（用于判断是否需要重新计算尺寸）
    _lastPropertySnapshot = CanvasElementClone.clone(activeElement);

    SmartDialog.show(
      builder: (context) => TextPropertyDialog(
        element: activeElement,
        onDeleteText: () {
          _deleteText();
        },
        onPropertyChanged: (update) {
          // 属性实时更新时的回调，立即刷新UI和重新计算尺寸
          _refreshTextBoxAfterPropertyChange();
          if (update) {
            _recordTextPropertyChange();
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

  /// 记录文本属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void _recordTextPropertyChange() {
    if (_activeElement == null ||
        _activeElement!.type != ElementType.text ||
        _lastElementProperties == null) {
      return;
    }

    final current = _activeElement!;
    final old = _lastElementProperties!;
    final boxes = _canvalsController.elements;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (old.fontSize != current.fontSize) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fontSize': old.fontSize},
          newProperties: {'fontSize': current.fontSize},
        ),
      );
    }

    if (old.fontFamily != current.fontFamily) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fontFamily': old.fontFamily},
          newProperties: {'fontFamily': current.fontFamily},
        ),
      );
    }

    if (old.fontWeight != current.fontWeight) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fontWeight': old.fontWeight},
          newProperties: {'fontWeight': current.fontWeight},
        ),
      );
    }

    if (old.textColor != current.textColor) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'textColor': old.textColor},
          newProperties: {'textColor': current.textColor},
        ),
      );
    }

    if (old.textAlpha != current.textAlpha) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'textAlpha': old.textAlpha},
          newProperties: {'textAlpha': current.textAlpha},
        ),
      );
    }

    if (old.lineHeight != current.lineHeight) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'lineHeight': old.lineHeight},
          newProperties: {'lineHeight': current.lineHeight},
        ),
      );
    }

    if (old.fontSpace != current.fontSpace) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'fontSpace': old.fontSpace},
          newProperties: {'fontSpace': current.fontSpace},
        ),
      );
    }

    if (old.align != current.align) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'align': old.align},
          newProperties: {'align': current.align},
        ),
      );
    }

    if (old.width != current.width) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'width': old.width},
          newProperties: {'width': current.width},
        ),
      );
    }

    if (old.height != current.height) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'height': old.height},
          newProperties: {'height': current.height},
        ),
      );
    }

    if (old.borderColor != current.borderColor) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderColor': old.borderColor},
          newProperties: {'borderColor': current.borderColor},
        ),
      );
    }

    if (old.borderAlpha != current.borderAlpha) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderAlpha': old.borderAlpha},
          newProperties: {'borderAlpha': current.borderAlpha},
        ),
      );
    }

    if (old.borderWidth != current.borderWidth) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'borderWidth': old.borderWidth},
          newProperties: {'borderWidth': current.borderWidth},
        ),
      );
    }

    if (old.isShawOpen != current.isShawOpen) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'isShawOpen': old.isShawOpen},
          newProperties: {'isShawOpen': current.isShawOpen},
        ),
      );
    }

    if (old.shawColor != current.shawColor) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawColor': old.shawColor},
          newProperties: {'shawColor': current.shawColor},
        ),
      );
    }

    if (old.shawAlpha != current.shawAlpha) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawAlpha': old.shawAlpha},
          newProperties: {'shawAlpha': current.shawAlpha},
        ),
      );
    }

    if (old.shawX != current.shawX) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawX': old.shawX},
          newProperties: {'shawX': current.shawX},
        ),
      );
    }

    if (old.shawY != current.shawY) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'shawY': old.shawY},
          newProperties: {'shawY': current.shawY},
        ),
      );
    }

    if (old.blurValue != current.blurValue) {
      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: {'blurValue': old.blurValue},
          newProperties: {'blurValue': current.blurValue},
        ),
      );
    }

    // 更新上一次的属性值
    _lastElementProperties = CanvasElementClone.clone(current);
  }

  /// 刷新文本框，重新计算尺寸（当属性变化时）
  /// 注意：属性值已经在 TextPropertyDialog 中实时更新，这里只需要重新计算尺寸并刷新UI
  void _refreshTextBoxAfterPropertyChange() {
    if (_activeElement == null || _activeElement!.type != ElementType.text) {
      return;
    }

    final box = _activeElement!;

    // 检查哪些属性改变了，判断是否需要重新计算尺寸
    // 如果只是对齐方式、颜色、描边、阴影等不影响尺寸的属性改变，就不重新计算尺寸
    bool needRecalculateSize = false;
    if (_lastPropertySnapshot != null) {
      final old = _lastPropertySnapshot!;
      // 检查影响尺寸的属性是否改变（与上一次比较，而不是与打开对话框时比较）
      needRecalculateSize =
          old.fontSize != box.fontSize ||
          old.fontFamily != box.fontFamily ||
          old.fontWeight != box.fontWeight ||
          old.lineHeight != box.lineHeight ||
          old.fontSpace != box.fontSpace;
    } else {
      // 如果没有快照，说明是第一次属性改变，需要检查是否真的需要重算
      // 如果只是对齐方式等不影响尺寸的属性改变，就不需要重算
      // 这里默认不重算，因为第一次打开对话框时，属性应该已经是正确的
      needRecalculateSize = false;
    }

    // 更新上一次的属性快照（在 setState 之前更新，避免下次比较时出错）
    _lastPropertySnapshot = CanvasElementClone.clone(box);

    setState(() {
      if (needRecalculateSize) {
        // 先计算单行文本需要的宽度（不考虑宽度限制）
        final singleLineSize = TextMeasureUtil.measureText(
          text: box.text,
          fontSize: box.fontSize,
          fontFamily: box.fontFamily,
          fontWeight: box.fontWeight,
          letterSpacing: box.fontSpace,
          lineHeight: box.lineHeight,
        );

        // 判断当前是否是多行状态
        // 如果保存的宽度存在且小于单行宽度，说明是多行状态，应该保持这个宽度
        final savedWidth = _savedTextWidth ?? box.width;
        final isMultiLine = savedWidth < singleLineSize.width;

        if (isMultiLine) {
          // 多行状态：保持宽度不变，只根据新属性重新计算高度
          final textSize = TextMeasureUtil.measureTextWithWidth(
            text: box.text,
            fontSize: box.fontSize,
            fontFamily: box.fontFamily,
            fontWeight: box.fontWeight,
            letterSpacing: box.fontSpace,
            lineHeight: box.lineHeight,
            maxWidth: savedWidth,
          );
          box.width = savedWidth; // 保持保存的宽度
          box.height = textSize.height; // 根据新属性重新计算高度
        } else {
          // 单行状态：根据新属性重新计算宽度和高度
          box.width = singleLineSize.width;
          box.height = singleLineSize.height;
        }
      }
      // 即使不需要重新计算尺寸，也需要调用 setState 来更新 UI
      // 这样可以确保对齐方式等属性的变化能够正确显示
      // 由于不重新计算尺寸，不会导致文字跳动
    });
  }

  /// 删除文本
  void _deleteText() {
    if (_activeElement != null) {
      debugPrint('删除文本');
      _canvasKey.currentState?.deleteBox(_activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 获取当前激活的元素
  CanvasElement? get _activeElement {
    final selectedId = _canvalsController.selectedId;
    if (selectedId.isEmpty) return null;

    final layers = _canvalsController.elements;
    try {
      return layers.firstWhere((layer) => layer.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时底部工具栏上移
      backgroundColor: cfff6f2fb,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: ScreenTools.statusBarHeight + 51.w,
            child: CanvasPointerWrapper(
              canvalsController: _canvalsController,
              canvasStatusManager: _canvasStatusManager,
              canvasKey: _canvasKey,
              canvasContainerKey: _canvasContainerKey,
              child: Container(
                width: ScreenTools.screenWidth,
                height:
                    ScreenTools.screenHeight -
                    ScreenTools.statusBarHeight -
                    ScreenTools.bottomBarHeight -
                    117.w,
                color: cfff6f2fb,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _canvalsController.getCanvalsSize(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    final canvasContent = Screenshot(
                      controller: _screenshotController,
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              key: _canvasContainerKey,
                              width: _canvalsController.canvalsWidth,
                              height: _canvalsController.canvalsHeight,
                              color: _canvalsController
                                  .canvasModel
                                  .fillColor
                                  .color
                                  .withValues(
                                    alpha: _canvalsController
                                        .canvasModel
                                        .fillAlpha,
                                  ),
                            ),
                            Positioned.fill(
                              child: OverflowBox(
                                minWidth: 0,
                                minHeight: 0,
                                maxWidth: double.infinity,
                                maxHeight: double.infinity,
                                alignment: Alignment.topLeft,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: CanvasEditorWidget(
                                    key: _canvasKey,
                                    historyManager: _historyManager,
                                    onContentChanged: () {
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                    canvasMatrix: _canvalsController
                                        .canvasModel
                                        .transform,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final boxes = _canvalsController.elements;
                    return Center(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Transform(
                              transform:
                                  _canvalsController.canvasModel.transform,
                              alignment: Alignment.topLeft,
                              child: canvasContent,
                            ),

                            Obx(
                              () => TransformCanvas(
                                elements: boxes,
                                selectedId: _canvalsController.selectedId,
                                canvasMatrix:
                                    _canvalsController.canvasModel.transform,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 顶部导航栏
          Positioned(
            left: 0,
            top: 0,
            child: Obx(
              () => CanvasAppBar(
                _handleBack,
                _handleUndo,
                _handleRedo,
                canUndo: _historyManager.canUndo,
                canRedo: _historyManager.canRedo,
              ),
            ),
          ),

          // 底部tabBar
          Positioned(
            left: 0,
            bottom: 0,
            child: CanvasBottomBar(
              onLayerTap: () {
                _toggleLayerDialog(true);
              },
              onAddImage: () {
                _addImageDialog(context);
              },
              onAddShape: _showShapeDialog,
              onAddText: () {
                _showTextInputDialog(context);
              },
              onSave: _showSaveTemplateDialog,
              onExport: _captureAndSave,
            ),
          ),

          // 缩放控制浮框（当缩放比例不是100%时显示，固定在顶部居中位置）
          if ((_canvalsController.canvasModel.scale - 1.0).abs() > 0.01)
            _buildScaleOverlay(),

          // 元素属性工具栏
          Obx(
            () => Positioned(
              left: 0,
              bottom: 66.w + ScreenTools.bottomBarHeight,
              child: ElementAttributeToolbar(
                activeElement: _activeElement,
                isCanvasSelected: _canvalsController.canvasModel.isSelected,
                onClose: () {
                  _canvalsController.select('');
                  if (_canvalsController.canvasModel.isSelected) {
                    setState(() {
                      _canvalsController.canvasModel.isSelected = false;
                    });
                  }
                },
                onCollapse: (text) {
                  _toggleLayerDialog(false);
                  if (text == "画布属性") {
                    _showCanvalsPropertyDialog();
                  } else {
                    // 根据元素类型显示不同的属性弹框
                    if (_activeElement?.type == ElementType.image) {
                      _showImagePropertyDialog();
                    } else if (_activeElement?.type == ElementType.rectangle ||
                        _activeElement?.type == ElementType.ellipse ||
                        _activeElement?.type == ElementType.line) {
                      _showShapePropertyDialog();
                    } else {
                      _showTextPropertyDialog();
                    }
                  }
                },
              ),
            ),
          ),

          // 图层弹框
          if (_showLayerDialog) _buildLayerDialog(),
        ],
      ),
    );
  }

  void _showCanvalsPropertyDialog() {
    final canvasModel = _canvalsController.canvasModel;

    // 获取画布图层
    SmartDialog.show(
      builder: (context) => CanvalsPropertyDialog(
        canvasModel: canvasModel,
        onPropertyChanged: (update) {
          setState(() {});
          // 每次属性改变时立即记录命令
          if (update) {
            _recordCanvasPropertyChange();
          }
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      // maskWidget: GestureDetector(
      //   onTap: () {
      //     _recordCanvasPropertyChange();
      //     SmartDialog.dismiss();
      //   },
      //   child: Container(color: Colors.transparent),
      // ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 记录画布属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void _recordCanvasPropertyChange() {
    if (_lastCanvasProperties == null) return;

    final canvasModel = _canvalsController.canvasModel;
    final last = _lastCanvasProperties!;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (last['fillColor'] != canvasModel.fillColor) {
      _historyManager.executeCommand(
        UpdateCanvasPropertiesCommand(
          canvasModel: canvasModel,
          oldProperties: {'fillColor': last['fillColor']},
          newProperties: {'fillColor': canvasModel.fillColor},
        ),
      );
    }

    if (last['fillAlpha'] != canvasModel.fillAlpha) {
      _historyManager.executeCommand(
        UpdateCanvasPropertiesCommand(
          canvasModel: canvasModel,
          oldProperties: {'fillAlpha': last['fillAlpha']},
          newProperties: {'fillAlpha': canvasModel.fillAlpha},
        ),
      );
    }

    // 更新上一次的属性值（保持所有属性的同步）
    _lastCanvasProperties = {
      'fillColor': canvasModel.fillColor,
      'fillAlpha': canvasModel.fillAlpha,
      'locked': canvasModel.locked, // 同步当前锁定状态
    };
  }

  /// 显示图片属性弹框
  void _showImagePropertyDialog() {
    if (_activeElement == null || _activeElement!.type != ElementType.image) {
      return;
    }
    // 初始化上一次的属性值
    _lastElementProperties = CanvasElementClone.clone(_activeElement!);

    SmartDialog.show(
      builder: (context) => ImagePropertyDialog(
        element: _activeElement,
        replaceImage: () {
          _replaceImage(context);
        },
        onValueChanged: (update) {
          setState(() {}); // 触发界面重绘
          // 每次属性改变时立即记录命令
          if (update) {
            _recordImagePropertyChange();
          }
        },
        onDeleteImage: () {
          _deleteImage();
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

  /// 记录图片属性变化（每次属性改变时立即调用）
  /// 每个属性变更都单独记录一个命令，确保撤销时按照操作顺序进行
  void _recordImagePropertyChange() {
    if (_activeElement == null ||
        _activeElement!.type != ElementType.image ||
        _lastElementProperties == null) {
      return;
    }

    final current = _activeElement!;
    final old = _lastElementProperties!;
    final boxes = _canvalsController.elements;

    // 检测每个单独变化的属性，为每个属性创建一个单独的命令
    // 按照检测顺序记录，确保撤销时按照相反顺序进行

    if (old.width != current.width) {
      _historyManager.executeCommand(
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
      _historyManager.executeCommand(
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

    if (old.imagePath != current.imagePath) {
      _historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: null,
          oldHeight: null,
          oldImagePath: old.imagePath,
          newWidth: null,
          newHeight: null,
          newImagePath: current.imagePath,
        ),
      );
    }

    if (old.imageAlpha != current.imageAlpha) {
      _historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: null,
          oldHeight: null,
          oldImagePath: null,
          newWidth: null,
          newHeight: null,
          newImagePath: null,
          oldImageAlpha: old.imageAlpha,
          newImageAlpha: current.imageAlpha,
        ),
      );
    }

    // 更新上一次的属性值
    _lastElementProperties = CanvasElementClone.clone(current);
  }

  /// 删除图片
  void _deleteImage() {
    if (_activeElement != null) {
      _canvasKey.currentState?.deleteBox(_activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 替换图片
  void _replaceImage(BuildContext context) {
    SelectSourceTools.chooseImages(
      context: context,
      onSuccess: (AssetEntity assetEntity) {
        final imagePath = assetEntity.relativePath;
        if (imagePath != null) {
          debugPrint('选择的图片路径: $imagePath');
          setState(() {
            _activeElement!.imagePath = imagePath;
          });
        }
      },
    );
  }

  // 增加图片
  void _addImageDialog(BuildContext context) async {
    _toggleLayerDialog(false);
    final res = await PermissionUtil.requestPhotoAlbumPermission();
    if (res && mounted) {
      SelectSourceTools.chooseImages(
        context: context,
        onSuccess: (AssetEntity assetEntity) {
          _canvalsController.addNewImage(
            assetEntity,
            targetCenter: _getCanvasCenter(),
          );
        },
      );
    } else {
      SmartDialog.show(
        builder: (context) => ConfirmPopWidget(
          title: '提示',
          subTitle: '打开相册以上传图片到编辑器\n中进行进一步编辑',
          sureTitle: "同意",
          sureAction: () {
            AppSettings.openAppSettings(type: AppSettingsType.settings);
          },
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
  }

  /// 显示图层弹框
  void _toggleLayerDialog(bool isLayer) {
    if (!isLayer && !_showLayerDialog) {
      return;
    }
    setState(() {
      _showLayerDialog = !_showLayerDialog;
    });
  }

  /// 显示形状弹框
  void _showShapeDialog() {
    _toggleLayerDialog(false);
    SmartDialog.show(
      builder: (context) => CanvalsShapeDialog(
        onShapeSelected: (type) {
          _canvasKey.currentState?.addShape(type, _getCanvasCenter());
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

  /// 显示文本输入对话框
  void _showTextInputDialog(BuildContext context) {
    _toggleLayerDialog(false);
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
          _canvasKey.currentState?.addBox(
            type: ElementType.text,
            text: text,
            center: _getCanvasCenter(),
          );
          Navigator.pop(context); // 关闭对话框
        },
      ),
    );
  }

  /// 显示保存模版弹框
  void _showSaveTemplateDialog() {
    _toggleLayerDialog(false);

    SmartDialog.show(
      builder: (context) => CanvalsSaveTemplateDialog(),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      clickMaskDismiss: false,
      maskColor: Colors.black,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 保存到系统相册
  Future<void> _captureAndSave() async {
    _toggleLayerDialog(false);
    final res = await PermissionUtil.requestPhotoAlbumPermission();
    if (res) {
      try {
        final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
        if (imageBytes != null) {
          final result = await ImageGallerySaverPlus.saveImage(
            imageBytes,
            quality: 100,
            name: "canvas_${DateTime.now().millisecondsSinceEpoch}",
          );
          if (result['isSuccess']) {
            showToast('图片已保存到相册');
            return;
          }
        }
        showToast('保存失败');
      } catch (e) {
        showToast('保存失败');
      }
    } else {
      SmartDialog.show(
        builder: (context) => ConfirmPopWidget(
          title: "提示",
          subTitle: "保存图片到相册，需要开启相册权限",
          sureTitle: "同意",
          sureAction: () {
            AppSettings.openAppSettings(type: AppSettingsType.settings);
          },
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
  }

  /// 返回操作
  void _handleBack() {
    Get.back();
  }

  /// 撤销操作
  void _handleUndo() {
    _toggleLayerDialog(false);
    _canvasKey.currentState?.undo();
  }

  /// 重做操作
  void _handleRedo() {
    _toggleLayerDialog(false);
    _canvasKey.currentState?.redo();
  }

  /// 构建缩放控制浮框（当缩放比例不是100%时显示）
  Widget _buildScaleOverlay() {
    return Positioned(
      right: 10.w,
      top: ScreenTools.statusBarHeight + 51.w,
      child: Center(
        child: CanvasControlWidget(
          scale: _canvalsController.canvasModel.scale,
          onFitScreen: () {
            _canvasStatusManager.resetMatrix(
              _canvalsController.canvasModel,
            ); // 适应屏幕：重置画布变换
          },
          onZoomIn: () {
            _canvasStatusManager.zoomIn(
              Size(
                _canvalsController.canvalsWidth,
                _canvalsController.canvalsHeight,
              ),
            ); // 放大画布
          },
          onZoomOut: () {
            _canvasStatusManager.zoomOut(
              Size(
                _canvalsController.canvalsWidth,
                _canvalsController.canvalsHeight,
              ),
            ); // 缩小画布
          },
        ),
      ),
    );
  }

  /// 构建图层弹框
  Widget _buildLayerDialog() {
    return Positioned(
      left: 16.w,
      bottom: 72.w + ScreenTools.bottomBarHeight, // 底部工具栏高度 + 10像素间距
      child: CanvalsLayerDialog(
        canvasModel: _canvalsController.canvasModel,
        layers: _canvalsController.elements,
        onLayerTap: (layerId) {
          // 选中元素时，确保画布未选中
          setState(() {
            _canvalsController.canvasModel.isSelected = false;
          });

          // 切换元素选中状态
          _canvalsController.isSelected(layerId)
              ? _canvalsController.deselect()
              : _canvalsController.select(layerId);
        },
        onLayerDelete: (layerId) {
          setState(() {
            _canvasKey.currentState?.deleteBox(layerId);
          });
        },
        onLayerReorder: (oldIndex, newIndex) {
          setState(() {
            _canvasKey.currentState?.reorderLayers(oldIndex, newIndex);
          });
        },
        onLayerToggleVisibility: (layerId) {
          final layers = _canvalsController.elements;
          final layer = layers.firstWhere((l) => l.id == layerId);
          final oldVisible = layer.hidden;
          setState(() {
            layer.hidden = !layer.hidden;
          });
          // 记录命令
          final boxes = _canvalsController.elements;
          _historyManager.executeCommand(
            ToggleVisibilityCommand(
              boxes: boxes,
              elementId: layerId,
              oldVisible: oldVisible,
              newVisible: layer.hidden,
            ),
          );
        },
        onLayerLock: (layerId) {
          final layers = _canvalsController.elements;
          final layer = layers.firstWhere((l) => l.id == layerId);
          setState(() {
            layer.locked = !layer.locked;
          });
        },
        onCanvalsActivie: () {
          setState(() {
            _canvalsController.canvasModel.isSelected = true;
            _canvalsController.deselect();
          });
        },
        onCanvalsLock: () {
          final canvasModel = _canvalsController.canvasModel;
          final oldLocked = canvasModel.locked;
          final newLocked = !oldLocked;

          setState(() {
            canvasModel.locked = newLocked;
            if (canvasModel.locked) {
              _canvalsController.deselect();
            }
          });

          // 立即记录锁定状态变更到历史
          _historyManager.executeCommand(
            UpdateCanvasPropertiesCommand(
              canvasModel: canvasModel,
              oldProperties: {'locked': oldLocked},
              newProperties: {'locked': newLocked},
            ),
          );

          // 更新上一次的属性值
          if (_lastCanvasProperties != null) {
            _lastCanvasProperties!['locked'] = newLocked;
          }
        },
      ),
    );
  }

  Offset _getCanvasCenter() {
    return Offset(
      _canvalsController.canvalsWidth / 2,
      _canvalsController.canvalsHeight / 2,
    );
  }
}
