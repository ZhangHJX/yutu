import 'dart:typed_data';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../widgets/index.dart';
import 'widgets/canvals_editor_widget.dart';
import 'canvals_controller.dart';
import '../../utils/text_measure_util.dart';
import 'package:screenshot/screenshot.dart';
import '../../history/index.dart';
import '../../gesture/index.dart';
import '../../model/index.dart';
import 'widgets/transform_canvas.dart';
import 'canvals_editor_page_undo_redo_mixin.dart';
import 'canvals_editor_page_dialog_mixin.dart';
import '../../draft/index.dart';
import '../../widgets/dialog/save/save_logic.dart';

class CanvasEditorPage extends StatefulWidget {
  const CanvasEditorPage({super.key});
  @override
  State<CanvasEditorPage> createState() => _CanvasEditorPagePageState();
}

class _CanvasEditorPagePageState extends State<CanvasEditorPage>
    with CanvasEditorUndoRedoMixin, CanvasEditorDialogMixin {
  final CanvalsController _canvalsController = Get.put(CanvalsController());
  final ScreenshotController _screenshotController = ScreenshotController();

  final GlobalKey<CanvasEditorWidgetState> _canvasKey =
      GlobalKey<CanvasEditorWidgetState>();
  final GlobalKey _canvasContainerKey = GlobalKey();
  bool _showLayerDialog = false; // 添加图层弹框显示状态

  // 画布手势管理器
  final _canvasStatusManager = CanvasStatusManager();

  // 实现 mixin 要求的抽象成员
  @override
  CanvalsController get canvalsController => _canvalsController;

  @override
  GlobalKey<CanvasEditorWidgetState> get canvasKey => _canvasKey;

  @override
  void toggleLayerDialog(bool isLayer) => _toggleLayerDialog(isLayer);

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
    // 初始化撤销/重做功能
    initUndoRedo();

    // 初始化画布属性快照
    initCanvasProperties();

    // 启动草稿自动保存（传递截图控制器）
    DraftManager().startAutoSave(
      _canvalsController,
      screenshotController: _screenshotController,
    );
    debugPrint("--画布页面的初始化---initState---");
  }

  @override
  void dispose() {
    // 停止自动保存并保存最后一次
    DraftManager().stopAutoSave();
    super.dispose();
  }

  /// 删除形状
  @override
  void deleteShape() {
    if (activeElement != null) {
      debugPrint('删除形状');
      _canvasKey.currentState?.deleteBox(activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 刷新文本框，重新计算尺寸（当属性变化时）
  /// 注意：属性值已经在 TextPropertyDialog 中实时更新，这里只需要重新计算尺寸并刷新UI
  @override
  void refreshTextBoxAfterPropertyChange() {
    if (activeElement == null || activeElement!.type != ElementType.text) {
      return;
    }

    final box = activeElement!;

    // 检查哪些属性改变了，判断是否需要重新计算尺寸
    // 如果只是对齐方式、颜色、描边、阴影等不影响尺寸的属性改变，就不重新计算尺寸
    bool needRecalculateSize = false;
    if (lastPropertySnapshot != null) {
      final old = lastPropertySnapshot!;
      // 检查影响尺寸的属性是否改变（与上一次比较，而不是与打开对话框时比较）
      needRecalculateSize =
          old.fontSize != box.fontSize ||
          old.familyKey != box.familyKey ||
          old.lineHeight != box.lineHeight ||
          old.fontSpace != box.fontSpace;
    } else {
      // 如果没有快照，说明是第一次属性改变，需要检查是否真的需要重算
      // 如果只是对齐方式等不影响尺寸的属性改变，就不需要重算
      // 这里默认不重算，因为第一次打开对话框时，属性应该已经是正确的
      needRecalculateSize = false;
    }

    // 更新上一次的属性快照（在 setState 之前更新，避免下次比较时出错）
    lastPropertySnapshot = CanvasElementClone.clone(box);

    setState(() {
      if (needRecalculateSize) {
        // 先计算单行文本需要的宽度（不考虑宽度限制）
        final singleLineSize = TextMeasureUtil.measureText(
          text: box.text,
          fontSize: box.fontSize,
          fontFamily: box.familyKey,
          letterSpacing: box.fontSpace,
          lineHeight: box.lineHeight,
        );

        // 判断当前是否是多行状态
        // 如果保存的宽度存在且小于单行宽度，说明是多行状态，应该保持这个宽度
        final savedWidth = savedTextWidth ?? box.width;
        final isMultiLine = savedWidth < singleLineSize.width;

        if (isMultiLine) {
          // 多行状态：保持宽度不变，只根据新属性重新计算高度
          final textSize = TextMeasureUtil.measureTextWithWidth(
            text: box.text,
            fontSize: box.fontSize,
            fontFamily: box.familyKey,
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
  @override
  void deleteText() {
    if (activeElement != null) {
      debugPrint('删除文本');
      _canvasKey.currentState?.deleteBox(activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时底部工具栏上移
      backgroundColor: "#F6F2FB".color,
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
              onTap: () => toggleLayerDialog(false),
              child: Container(
                width: ScreenTools.screenWidth,
                height:
                    ScreenTools.screenHeight -
                    ScreenTools.statusBarHeight -
                    ScreenTools.bottomBarHeight -
                    117.w,
                color: "#F6F2FB".color,
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
                                    historyManager: historyManager,
                                    onContentChanged: () {
                                      if (mounted) {
                                        setState(() {});
                                        // 通知草稿管理器内容已变更
                                        DraftManager().notifyElementsChanged();
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
                handleUndo,
                handleRedo,
                canUndo: canUndo,
                canRedo: canRedo,
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
                addImageDialog(context);
              },
              onAddShape: showShapeDialog,
              onAddText: () {
                showTextInputDialog(context);
              },
              onSave: showSaveTemplateDialog,
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
              right: 0,
              bottom: 66.w + ScreenTools.bottomBarHeight,
              child: ElementAttributeToolbar(
                activeElement: activeElement,
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
                  toggleLayerDialog(false);
                  if (text == "画布属性") {
                    showCanvalsPropertyDialog();
                  } else {
                    // 根据元素类型显示不同的属性弹框
                    if (activeElement?.type == ElementType.image) {
                      showImagePropertyDialog(context);
                    } else if (activeElement?.type == ElementType.rectangle ||
                        activeElement?.type == ElementType.ellipse ||
                        activeElement?.type == ElementType.line) {
                      showShapePropertyDialog();
                    } else {
                      showTextPropertyDialog();
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

  /// 删除图片
  @override
  void deleteImage() {
    // if (activeElement != null) {
    //   final fullPath = CanvalsFileManager.getImageFullPathByFileName(
    //     activeElement!.fileName,
    //   );
    //   CanvalsFileManager.deleteFileByPath(fullPath);
    //   _canvasKey.currentState?.deleteBox(activeElement!.id);
    //   SmartDialog.dismiss();
    // }
  }

  /// 替换图片
  @override
  void replaceImage(BuildContext context) async {
    final res = await PermissionUtil.requestPhotoAlbumPermission();
    if (!res) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    // ImageStorageManager.chooseImages(
    //   context: context,
    //   onSuccess: (String fileName, double width, double height) {
    //     final oldPath = CanvalsFileManager.getImageFullPathByFileName(
    //       activeElement!.fileName,
    //     );
    //     CanvalsFileManager.deleteFileByPath(oldPath);
    //     setState(() {
    //       activeElement!.fileName = basename(fileName);
    //     });
    //   },
    // );
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

  /// 保存到系统相册
  Future<void> _captureAndSave() async {
    toggleLayerDialog(false);
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
      showPermissionDialog(
        title: "提示",
        subTitle: "保存图片到相册，需要开启相册权限",
        sureTitle: "同意",
        sureAction: () {
          AppSettings.openAppSettings(type: AppSettingsType.settings);
        },
      );
    }
  }

  @override
  Future<Uint8List?> getCurrentCanvals() async {
    final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
    return imageBytes;
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
          historyManager.executeCommand(
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
          historyManager.executeCommand(
            UpdateCanvasPropertiesCommand(
              canvasModel: canvasModel,
              oldProperties: {'locked': oldLocked},
              newProperties: {'locked': newLocked},
            ),
          );

          // 更新上一次的属性值
          updateLastCanvasProperty('locked', newLocked);
        },
      ),
    );
  }

  @override
  Offset getCanvasCenter() {
    return Offset(
      _canvalsController.canvalsWidth / 2,
      _canvalsController.canvalsHeight / 2,
    );
  }

  /// 返回操作
  void _handleBack() {
    if (DraftManager().ishChanage) {
      showIsSaveDraftDialog(() async {
        // 获取画布截图
        final imageBytes = await getCurrentCanvals();
        if (imageBytes == null) {
          showToast('画布截图失败');
          return;
        }
        // 创建或获取 SaveLogic 实例
        SaveLogic saveLogic;
        if (Get.isRegistered<SaveLogic>(tag: saveDialog)) {
          saveLogic = Get.find<SaveLogic>(tag: saveDialog);
        } else {
          saveLogic = Get.put(SaveLogic(), tag: saveDialog);
        }

        // 设置画布截图
        saveLogic.canvalsImage = imageBytes;

        // 调用保存草稿方法
        await saveLogic.saveAsDraft();

        SmartDialog.dismiss(); // 关闭保存草稿对话框
        Get.back(); // 返回上一页
      });
      return;
    }

    DraftManager().deleteDraft();
    Get.back();
  }
}
