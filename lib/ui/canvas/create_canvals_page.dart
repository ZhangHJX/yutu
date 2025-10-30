import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'widgets/canvas_app_bar_widget.dart';
import 'widgets/canvas_bottom_bar_widget.dart';
import 'widgets/dialog/canvals_layer_dialog.dart';
import 'widgets/dialog/canvals_save_dialog.dart';
import 'widgets/property/element_attribute_toolbar.dart';
import 'widgets/property/image_property_dialog.dart';
import 'widgets/property/shape_property_dialog.dart';
import 'widgets/property/text_property_dialog.dart';
import 'widgets/dialog/text_input_dialog.dart';
import 'widgets/dialog/canvals_shape_dialog.dart';
import './edit_box/edit_canvals_widget.dart';
import 'controllers/canvals_controller.dart';
import './controllers/create_design_model.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class CreateCanvalsPage extends StatefulWidget {
  const CreateCanvalsPage({super.key});

  @override
  State<CreateCanvalsPage> createState() => _CreateCanvalsPageState();
}

class _CreateCanvalsPageState extends State<CreateCanvalsPage> {
  final CanvalsController _canvalsController = Get.put(CanvalsController());
  late DesignCanvalsModel _canvalsModel;
  final ScreenshotController _screenshotController = ScreenshotController();

  final GlobalKey<CanvasEditorWidgetState> _canvasKey =
      GlobalKey<CanvasEditorWidgetState>();

  final GlobalKey _layerButtonKey = GlobalKey();
  bool _showLayerDialog = false; // 添加图层弹框显示状态

  @override
  void initState() {
    super.initState();
  }

  /// 显示形状弹框
  void _showShapeDialog() {
    SmartDialog.show(
      builder: (context) => CanvalsShapeDialog(
        onShapeSelected: (shapeType) {
          _canvasKey.currentState?.addShape(shapeType);
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

  /// 显示形状属性弹框
  void _showShapePropertyDialog() {
    SmartDialog.show(
      builder: (context) => ShapePropertyDialog(
        editBoxData: _activeElement,
        onDeleteShape: () {
          _deleteShape();
        },
        onPropertiesChanged: (updatedData) {
          // 属性已经直接更新到 EditBoxData 对象，画布会自动响应
          setState(() {}); // 触发界面重绘
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () => SmartDialog.dismiss(),
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
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
    SmartDialog.show(
      builder: (context) => TextPropertyDialog(
        onDeleteText: () {
          _deleteText();
        },
      ),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: Colors.black.withValues(alpha: 0.4),
      maskWidget: GestureDetector(
        onTap: () => SmartDialog.dismiss(),
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 删除文本
  void _deleteText() {
    if (_activeElement != null) {
      debugPrint('删除文本');
      _canvasKey.currentState?.deleteBox(_activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 显示文本输入对话框
  void _showTextInputDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许控制高度
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => TextInputDialog(
        onConfirm: (text) {
          _canvasKey.currentState?.addBox(type: ElementType.text, text: text);
          Navigator.pop(context); // 关闭对话框
        },
      ),
    );
  }

  /// 获取当前激活的元素
  EditBoxData? get _activeElement {
    final selectedId = _canvalsController.selectedId;
    if (selectedId.isEmpty) return null;

    final layers = _canvasKey.currentState?.layers ?? [];
    try {
      return layers.firstWhere((layer) => layer.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  /// 显示保存模版弹框
  void _showSaveTemplateDialog() {
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

  /// 显示图层弹框
  void _toggleLayerDialog() {
    setState(() {
      _showLayerDialog = !_showLayerDialog;
    });
  }

  Future<void> _captureAndSave() async {
    // 请求存储权限
    final res = await PermissionUtil.requestGalleryReadPermission();
    if (res) {
      try {
        // 截取 widget
        final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);

        if (imageBytes != null) {
          // 保存到相册
          final result = await ImageGallerySaver.saveImage(
            imageBytes,
            quality: 100,
            name: "canvas_${DateTime.now().millisecondsSinceEpoch}",
          );

          if (result['isSuccess']) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('图片已保存到相册')));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _canvalsModel = Get.arguments as DesignCanvalsModel;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时底部工具栏上移
      backgroundColor: cfff6f2fb,
      body: Stack(
        children: [
          CanvasAppBar(),

          Positioned(
            left: 0,
            top: ScreenTools.statusBarHeight + 51.w,
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
                  // 计算画布宽高比
                  final availableRatio =
                      constraints.maxWidth / constraints.maxHeight;

                  // 根据比例确定最终显示尺寸
                  double displayWidth;
                  double displayHeight;

                  if (_canvalsModel.canvasRatio > availableRatio) {
                    // 画布更宽，以宽度为基准充满
                    displayWidth = constraints.maxWidth;
                    displayHeight =
                        constraints.maxWidth / _canvalsModel.canvasRatio;
                  } else {
                    // 画布更高，以高度为基准充满
                    displayHeight = constraints.maxHeight;
                    displayWidth =
                        constraints.maxHeight * _canvalsModel.canvasRatio;
                  }

                  return Screenshot(
                    controller: _screenshotController,
                    child: Center(
                      child: Container(
                        color: Colors.green,
                        width: displayWidth,
                        height: displayHeight,
                        child: CanvasEditorWidget(key: _canvasKey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          CanvasBottomBar(
            layerButtonKey: _layerButtonKey,
            onLayerTap: _toggleLayerDialog,
            onAddImage: () {
              _canvalsController.selectImageHelper.onlyChooseImages(
                onSuccess: () {
                  final imagePath = _canvalsController.selectImageHelper.image;
                  if (imagePath != null) {
                    debugPrint('选择的图片路径: $imagePath');
                    _canvalsController.addNewImage(imagePath);
                  }
                },
              );
            },
            onAddShape: _showShapeDialog,
            onAddText: _showTextInputDialog,
            onSave: _showSaveTemplateDialog,
            onExport: _captureAndSave,
          ),

          // 元素属性工具栏
          Obx(
            () => Positioned(
              left: 0,
              bottom: 66.w + ScreenTools.bottomBarHeight,
              child: ElementAttributeToolbar(
                activeElement: _activeElement,
                onClose: () {
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
                },
                onCollapse: () {
                  _canvalsController.select('');
                },
              ),
            ),
          ),

          // 图层弹框
          if (_showLayerDialog)
            Positioned(
              left: 16.w,
              bottom: 72.w + ScreenTools.bottomBarHeight, // 底部工具栏高度 + 10像素间距
              child: CanvalsLayerDialog(
                height: 271.w,
                width: 163.w,
                layers: _canvasKey.currentState?.layers ?? [],
                onLayerTap: (layerId) {
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
              ),
            ),
        ],
      ),
    );
  }

  /// 显示图片属性弹框
  void _showImagePropertyDialog() {
    SmartDialog.show(
      builder: (context) => ImagePropertyDialog(
        imagePath: _activeElement?.imagePath ?? '',
        currentWidth: _activeElement?.width,
        currentHeight: _activeElement?.height,
        onSizeChanged: (width, height) {
          _updateImageSize(width, height);
        },
        onReplaceImage: () {
          _replaceImage();
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
        onTap: () => SmartDialog.dismiss(),
        child: Container(color: Colors.transparent),
      ),
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 删除图片
  void _deleteImage() {
    if (_activeElement != null) {
      _canvasKey.currentState?.deleteBox(_activeElement!.id);
      SmartDialog.dismiss();
    }
  }

  /// 更新图片尺寸
  void _updateImageSize(double width, double height) {
    if (_activeElement != null) {
      setState(() {
        _activeElement!.width = width;
        _activeElement!.height = height;
      });
    }
  }

  /// 替换图片
  void _replaceImage() {
    if (_activeElement != null) {
      debugPrint('替换图片');
      _canvalsController.selectImageHelper.onlyChooseImages(
        onSuccess: () {
          final imagePath = _canvalsController.selectImageHelper.image;
          if (imagePath != null) {
            debugPrint('选择的图片路径: $imagePath');
            _canvalsController.addNewImage(imagePath);
          }
        },
      );
    }
  }
}
