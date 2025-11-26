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
import '../history/canvas_history_manager.dart';
import '../gesture/canvas_status_manager.dart';
import '../utils/edit_box_data_clone.dart';
import '../utils/index.dart';
import '../model/index.dart';
import '../canvals/transform_canvas.dart';

class CanvasEditorPage extends StatefulWidget {
  const CanvasEditorPage({super.key});
  @override
  State<CanvasEditorPage> createState() => _CanvasEditorPagePageState();
}

class _CanvasEditorPagePageState extends State<CanvasEditorPage> {
  final CanvalsController _canvalsController = Get.put(CanvalsController());
  final ScreenshotController _screenshotController = ScreenshotController();
  final CanvasHistoryManager _historyManager = CanvasHistoryManager();

  late CanvasModel _canvalsModel;
  final GlobalKey<CanvasEditorWidgetState> _canvasKey =
      GlobalKey<CanvasEditorWidgetState>();

  final GlobalKey _layerButtonKey = GlobalKey();
  final GlobalKey _containerKey = GlobalKey(); // 用于获取 Container 的 RenderBox
  final GlobalKey _canvasContainerKey =
      GlobalKey(); // 用于获取画布 Container 的 RenderBox
  bool _showLayerDialog = false; // 添加图层弹框显示状态
  double? _savedTextWidth; // 保存打开文本属性对话框时的宽度

  // 用于保存对话框打开时的属性快照（用于历史记录）
  CanvasElement? _propertyDialogSnapshot;
  // 用于保存上一次的属性值（用于判断是否需要重新计算尺寸）
  CanvasElement? _lastPropertySnapshot;
  // 画布手势管理器
  final _canvasStatusManager = CanvasStatusManager();

  @override
  void initState() {
    super.initState();
    // 监听画布变换变化（统一写回 CanvasModel）
    _canvasStatusManager.onMatrixChanged = (matrix, scale, offset) {
      if (!mounted) return;
      setState(() {
        _canvalsModel.updateMatrix4(matrix, scale, offset);
      });
    };
  }

  /// 显示形状属性弹框
  void _showShapePropertyDialog() {
    if (_activeElement == null) return;

    // 保存属性快照
    _propertyDialogSnapshot = CanvasElementClone.clone(_activeElement!);

    SmartDialog.show(
      builder: (context) => ShapePropertyDialog(
        element: _activeElement,
        onDeleteShape: () {
          _deleteShape();
        },
        onPropertiesChanged: (updatedData) {
          // 属性已经直接更新到 CanvasElement 对象，画布会自动响应
          setState(() {}); // 触发界面重绘
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () {
          _recordShapePropertyChange();
          SmartDialog.dismiss();
        },
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 记录形状属性变化
  void _recordShapePropertyChange() {
    if (_activeElement == null || _propertyDialogSnapshot == null) return;

    final current = _activeElement!;
    final old = _propertyDialogSnapshot!;

    // 检查是否有实际变化
    final hasChanged =
        old.fillColor != current.fillColor ||
        old.borderColor != current.borderColor ||
        old.borderWidth != current.borderWidth ||
        old.isShawOpen != current.isShawOpen ||
        old.shawColor != current.shawColor ||
        old.shawX != current.shawX ||
        old.shawY != current.shawY ||
        old.blurValue != current.blurValue ||
        old.height != current.height;

    if (hasChanged) {
      final oldProperties = {
        'fillColor': old.fillColor,
        'borderColor': old.borderColor,
        'borderWidth': old.borderWidth,
        'isShawOpen': old.isShawOpen,
        'shawColor': old.shawColor,
        'shawX': old.shawX,
        'shawY': old.shawY,
        'blurValue': old.blurValue,
        'height': old.height,
      };

      final newProperties = {
        'fillColor': current.fillColor,
        'borderColor': current.borderColor,
        'borderWidth': current.borderWidth,
        'isShawOpen': current.isShawOpen,
        'shawColor': current.shawColor,
        'shawX': current.shawX,
        'shawY': current.shawY,
        'blurValue': current.blurValue,
        'height': current.height,
      };

      final boxes = _canvasKey.currentState?.boxesList ?? [];
      _historyManager.executeCommand(
        UpdateShapePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: oldProperties,
          newProperties: newProperties,
        ),
      );
    }

    _propertyDialogSnapshot = null;
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

    // 保存属性快照
    _propertyDialogSnapshot = CanvasElementClone.clone(activeElement);

    // 保存上一次的属性值（用于判断是否需要重新计算尺寸）
    _lastPropertySnapshot = CanvasElementClone.clone(activeElement);

    SmartDialog.show(
      builder: (context) => TextPropertyDialog(
        element: activeElement,
        onDeleteText: () {
          _deleteText();
        },
        onPropertyChanged: () {
          // 属性实时更新时的回调，立即刷新UI和重新计算尺寸
          _refreshTextBoxAfterPropertyChange();
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () {
          _recordTextPropertyChange();
          SmartDialog.dismiss();
        },
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 记录文本属性变化
  void _recordTextPropertyChange() {
    if (_activeElement == null ||
        _activeElement!.type != ElementType.text ||
        _propertyDialogSnapshot == null)
      return;

    final current = _activeElement!;
    final old = _propertyDialogSnapshot!;

    // 检查是否有实际变化
    final hasChanged =
        old.fontSize != current.fontSize ||
        old.fontFamily != current.fontFamily ||
        old.fontWeight != current.fontWeight ||
        old.textColor != current.textColor ||
        old.lineHeight != current.lineHeight ||
        old.fontSpace != current.fontSpace ||
        old.align != current.align ||
        old.width != current.width ||
        old.height != current.height ||
        old.position.dx != current.position.dx ||
        old.position.dy != current.position.dy;

    if (hasChanged) {
      final boxes = _canvasKey.currentState?.boxesList ?? [];

      // 重新计算位置（因为尺寸变化可能导致位置变化）
      final oldPosition = old.position;
      final newPosition = current.position;

      final oldProperties = {
        'fontSize': old.fontSize,
        'fontFamily': old.fontFamily,
        'fontWeight': old.fontWeight,
        'textColor': old.textColor,
        'lineHeight': old.lineHeight,
        'fontSpace': old.fontSpace,
        'align': old.align,
        'width': old.width,
        'height': old.height,
        'position': oldPosition,
      };

      final newProperties = {
        'fontSize': current.fontSize,
        'fontFamily': current.fontFamily,
        'fontWeight': current.fontWeight,
        'textColor': current.textColor,
        'lineHeight': current.lineHeight,
        'fontSpace': current.fontSpace,
        'align': current.align,
        'width': current.width,
        'height': current.height,
        'position': newPosition,
      };

      _historyManager.executeCommand(
        UpdateTextPropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldProperties: oldProperties,
          newProperties: newProperties,
        ),
      );
    }

    _propertyDialogSnapshot = null;
    _lastPropertySnapshot = null;
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

    final layers = _canvasKey.currentState?.layers ?? [];
    try {
      return layers.firstWhere((layer) => layer.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _canvalsModel = Get.arguments as CanvasModel;
    _canvasStatusManager.matrix = _canvalsModel.transform;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时底部工具栏上移
      backgroundColor: cfff6f2fb,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: ScreenTools.statusBarHeight + 51.w,
            child: Listener(
              onPointerDown: (event) {
                _canvalsController.currentPoint = event;

                if (_canvalsController.selectedId.isNotEmpty) {
                  final localPos = MatrixUtilsX.canvasLocal(
                    event.position,
                    _canvasContainerKey,
                  );
                  _canvasKey.currentState?.handlePointerDown(
                    PointerDownEvent(
                      position: localPos,
                      pointer: event.pointer,
                    ),
                  );
                } else {
                  _canvasStatusManager.handlePointerDown(
                    event,
                    _canvalsModel.locked,
                  );
                }
              },
              onPointerMove: (event) {
                if (_canvalsController.selectedId.isNotEmpty) {
                  final localPos = MatrixUtilsX.canvasLocal(
                    event.position,
                    _canvasContainerKey,
                  );
                  _canvasKey.currentState?.handlePointerMove(
                    PointerMoveEvent(
                      position: localPos,
                      pointer: event.pointer,
                      delta: event.delta,
                    ),
                  );
                } else {
                  _canvasStatusManager.handlePointerMove(
                    event,
                    _canvalsModel.locked,
                  );
                }
              },
              onPointerUp: (event) {
                final localPos = MatrixUtilsX.canvasLocal(
                  event.position,
                  _canvasContainerKey,
                );
                if (_canvalsController.selectedId.isNotEmpty) {
                  _canvasKey.currentState?.handlePointerUp(
                    PointerUpEvent(position: localPos, pointer: event.pointer),
                  );
                } else {
                  _canvasStatusManager.handlePointerUp(
                    event,
                    _canvalsModel.locked,
                  );
                }
              },
              onPointerCancel: (event) {
                if (_canvalsController.selectedId.isNotEmpty) {
                } else {
                  _canvasStatusManager.handlePointerCancel(
                    event,
                    _canvalsModel.locked,
                  );
                }
              },
              child: GestureDetector(
                onTap: () {
                  final element = MatrixUtilsXGesture.detectHitElement(
                    _canvalsController.currentPoint!,
                    _canvasContainerKey,
                    _canvasKey.currentState?.boxes ?? [],
                    _canvalsController.canvalsSize,
                    _canvalsModel.transform,
                  );
                  if (element == null || element.id.isEmpty) {
                    _canvalsController.deselect();
                    return;
                  }

                  if (_canvalsController.isSelected(element.id) &&
                      element.type == ElementType.text) {
                    _canvasKey.currentState?.showTextInputDialog(element.id);
                  } else {
                    _canvalsController.toggleSelection(element.id);
                  }
                },
                child: Container(
                  key: _containerKey,
                  width: ScreenTools.screenWidth,
                  height:
                      ScreenTools.screenHeight -
                      ScreenTools.statusBarHeight -
                      ScreenTools.bottomBarHeight -
                      117.w,
                  color: cfff6f2fb,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _canvalsController.canvalsSize = _canvalsModel
                          .getCanvalsSize(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                      final logicSize = Size(
                        _canvalsModel.width,
                        _canvalsModel.height,
                      );

                      final canvasContent = ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              key: _canvasContainerKey,
                              width: _canvalsController.canvalsSize.width,
                              height: _canvalsController.canvalsSize.height,
                              decoration: BoxDecoration(
                                color: _canvalsModel.fillColor.color.withValues(
                                  alpha: _canvalsModel.fillAlpha,
                                ),
                                border: Border.all(
                                  color: _canvalsModel.borderColor.color
                                      .withValues(
                                        alpha: _canvalsModel.borderWidth > 0
                                            ? _canvalsModel.borderAlpha
                                            : 0.0,
                                      ),
                                  width: _canvalsModel.borderWidth,
                                ),
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
                                    canvasMatrix: _canvalsModel.transform,
                                    canvasSize: logicSize,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      final boxes = _canvasKey.currentState?.boxesList ?? [];

                      return Center(
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Screenshot(
                                controller: _screenshotController,
                                child: Transform(
                                  transform: _canvalsModel.transform,
                                  alignment: Alignment.topLeft,
                                  child: canvasContent,
                                ),
                              ),
                              Obx(
                                () => TransformCanvas(
                                  elements: boxes,
                                  selectedId: _canvalsController.selectedId,
                                  canvasMatrix: _canvalsModel.transform,
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

          // 缩放控制浮框（当缩放比例不是100%时显示，固定在顶部居中位置）
          if ((_canvalsModel.scale - 1.0).abs() > 0.01) _buildScaleOverlay(),

          // 底部tabBar
          Positioned(
            left: 0,
            bottom: 0,
            child: CanvasBottomBar(
              layerButtonKey: _layerButtonKey,
              onLayerTap: () {
                _toggleLayerDialog(true);
              },
              onAddImage: _addImageDialog,
              onAddShape: _showShapeDialog,
              onAddText: _showTextInputDialog,
              onSave: _showSaveTemplateDialog,
              onExport: _captureAndSave,
            ),
          ),

          // 元素属性工具栏
          Obx(
            () => Positioned(
              left: 0,
              bottom: 66.w + ScreenTools.bottomBarHeight,
              child: ElementAttributeToolbar(
                activeElement: _activeElement,
                isCanvasSelected: _canvalsModel.isSelected,
                onClose: () {
                  _canvalsController.select('');
                  if (_canvalsModel.isSelected) {
                    setState(() {
                      _canvalsModel.isSelected = false;
                    });
                  }
                },
                onCollapse: (text) {
                  _toggleLayerDialog(false);
                  if (text == "图层属性") {
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
    // 获取画布图层
    SmartDialog.show(
      builder: (context) => CanvalsPropertyDialog(
        canvasModel: _canvalsModel,
        onPropertyChanged: () {
          setState(() {}); // 触发界面重绘
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

  /// 显示图片属性弹框
  void _showImagePropertyDialog() {
    if (_activeElement == null || _activeElement!.type != ElementType.image) {
      return;
    }
    // 保存属性快照
    _propertyDialogSnapshot = CanvasElementClone.clone(_activeElement!);

    SmartDialog.show(
      builder: (context) => ImagePropertyDialog(
        element: _activeElement,
        replaceImage: () {
          _replaceImage();
        },
        onValueChanged: () {
          setState(() {}); // 触发界面重绘
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
          _recordImagePropertyChange();
          SmartDialog.dismiss();
        },
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 记录图片属性变化
  void _recordImagePropertyChange() {
    if (_activeElement == null ||
        _activeElement!.type != ElementType.image ||
        _propertyDialogSnapshot == null)
      return;

    final current = _activeElement!;
    final old = _propertyDialogSnapshot!;

    // 检查是否有实际变化
    final hasChanged =
        old.width != current.width ||
        old.height != current.height ||
        old.imagePath != current.imagePath;

    if (hasChanged) {
      final boxes = _canvasKey.currentState?.boxesList ?? [];
      _historyManager.executeCommand(
        UpdateImagePropertiesCommand(
          boxes: boxes,
          elementId: current.id,
          oldWidth: old.width,
          oldHeight: old.height,
          oldImagePath: old.imagePath,
          newWidth: current.width,
          newHeight: current.height,
          newImagePath: current.imagePath,
        ),
      );
    }

    _propertyDialogSnapshot = null;
  }

  /// 删除图片
  void _deleteImage() {
    if (_activeElement != null) {
      _canvasKey.currentState?.deleteBox(_activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 替换图片
  void _replaceImage() {
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
  void _addImageDialog() async {
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
        builder: (context) => PermissionHandlerWidget(),
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
  void _showTextInputDialog() {
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
        builder: (context) => PermissionHandlerWidget(),
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
          scale: _canvalsModel.scale,
          onFitScreen: () {
            _canvasStatusManager.resetMatrix(_canvalsModel); // 适应屏幕：重置画布变换
          },
          onZoomIn: () {
            _canvasStatusManager.zoomIn(_canvalsController.canvalsSize); // 放大画布
          },
          onZoomOut: () {
            _canvasStatusManager.zoomOut(
              _canvalsController.canvalsSize,
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
        canvasModel: _canvalsModel,
        layers: _canvasKey.currentState?.layers ?? [],
        onLayerTap: (layerId) {
          // 选中元素时，确保画布未选中
          setState(() {
            _canvalsModel.isSelected = false;
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
          final layers = _canvasKey.currentState?.layers ?? [];
          final layer = layers.firstWhere((l) => l.id == layerId);
          final oldVisible = layer.hidden;
          setState(() {
            layer.hidden = !layer.hidden;
          });
          // 记录命令
          final boxes = _canvasKey.currentState?.boxesList ?? [];
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
          final layers = _canvasKey.currentState?.layers ?? [];
          final layer = layers.firstWhere((l) => l.id == layerId);
          setState(() {
            layer.locked = !layer.locked;
          });
        },
        onCanvalsActivie: () {
          setState(() {
            _canvalsModel.isSelected = true;
            _canvalsController.deselect();
          });
        },
        onCanvalsLock: () {
          setState(() {
            _canvalsModel.locked = !_canvalsModel.locked;
            if (_canvalsModel.locked) {
              _canvalsController.deselect();
            }
          });
        },
      ),
    );
  }

  Offset _getCanvasCenter() {
    return Offset(
      _canvalsController.canvalsSize.width / 2,
      _canvalsController.canvalsSize.height / 2,
    );
  }
}
