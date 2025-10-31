import 'dart:io';
import 'dart:ui' as ui;

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../controllers/canvals_controller.dart';
import '../widgets/dialog/canvals_shape_dialog.dart';
import '../controllers/create_design_model.dart';
import 'edit_content_box.dart';
import '../managers/canvas_gesture_manager.dart';
import '../widgets/dialog/text_input_dialog.dart';
import '../../../utils/text_measure_util.dart';

class CanvasEditorWidget extends StatefulWidget {
  const CanvasEditorWidget({super.key});
  @override
  State<CanvasEditorWidget> createState() => CanvasEditorWidgetState();
}

class CanvasEditorWidgetState extends State<CanvasEditorWidget> {
  late CanvalsController _selectionController;
  final List<EditBoxData> boxes = [];

  // 手势管理器
  final _gestureManager = CanvasGestureManager();

  /// 获取图层列表（按显示顺序，最上面的在最后）
  List<EditBoxData> get layers => List.from(boxes);

  /// 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    setState(() {
      final item = boxes.removeAt(oldIndex);
      boxes.insert(newIndex, item);
    });
  }

  /// 添加形状元素
  void addShape(ShapeType shapeType) {
    ElementType elementType;
    String shapeName;
    double boxWidth = 150.w;
    double boxHeight = 150.w;

    switch (shapeType) {
      case ShapeType.rectangle:
        elementType = ElementType.rectangle;
        shapeName = '矩形';
        break;
      case ShapeType.ellipse:
        elementType = ElementType.ellipse;
        shapeName = '椭圆';
        boxWidth = 150.w;
        boxHeight = 87.w;
        break;
      case ShapeType.line:
        elementType = ElementType.line;
        shapeName = '线条';
        boxWidth = 216.w;
        boxHeight = 20.w;
        break;
    }

    final newId = _selectionController.generateId();

    // 获取画布容器的实际尺寸
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    double canvasWidth = ScreenTools.screenWidth; // 默认宽度
    double canvasHeight = ScreenTools.screenHeight; // 默认高度

    if (renderBox != null) {
      canvasWidth = renderBox.size.width;
      canvasHeight = renderBox.size.height;
    }

    // 计算子组件在画布中心的位置
    final centerX = (canvasWidth - boxWidth) / 2; // 文本框宽度的一半
    final centerY = (canvasHeight - boxHeight) / 2; // 文本框高度的一半

    setState(() {
      boxes.add(
        EditBoxData(
          id: newId,
          text: shapeName,
          position: Offset(centerX, centerY),
          type: elementType,
          width: boxWidth,
          height: boxHeight,
        ),
      );
    });
    // 自动选中新添加的元素
    _selectionController.select(newId);
  }

  @override
  void initState() {
    super.initState();
    _selectionController = Get.put(CanvalsController());

    _gestureManager.onDoubleTap = (String boxId) {
      debugPrint("----------$boxId--------");
      showTextInputDialog(boxId);
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 获取图片的实际尺寸
  Future<Size?> _getImageSize(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('图片文件不存在: $imagePath');
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('获取图片尺寸失败: $e');
      return null;
    }
  }

  /// 计算适合画布的图片尺寸
  /// [imageSize] 图片原始尺寸
  /// [maxWidth] 画布最大宽度
  /// [maxHeight] 画布最大高度
  /// 返回缩放后的尺寸，保持宽高比
  Size _calculateFitSize(Size imageSize, double maxWidth, double maxHeight) {
    // 设置最大显示尺寸（比如不超过画布的80%）
    final maxDisplayWidth = maxWidth * 0.8;
    final maxDisplayHeight = maxHeight * 0.8;

    double width = imageSize.width;
    double height = imageSize.height;

    // 如果图片太大，按比例缩小
    if (width > maxDisplayWidth || height > maxDisplayHeight) {
      final widthRatio = maxDisplayWidth / width;
      final heightRatio = maxDisplayHeight / height;
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      width = width * ratio;
      height = height * ratio;
    }

    // 设置最小尺寸（比如至少100像素）
    const minSize = 100.0;
    if (width < minSize) {
      final ratio = minSize / width;
      width = minSize;
      height = height * ratio;
    }
    if (height < minSize) {
      final ratio = minSize / height;
      height = height * ratio;
      width = width * ratio;
    }

    return Size(width, height);
  }

  Future<void> addBox({
    required ElementType type,
    String imagePath = '',
    String text = '',
  }) async {
    final newId = _selectionController.generateId();

    // 获取画布容器的实际尺寸
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    double canvasWidth = ScreenTools.screenWidth; // 默认宽度
    double canvasHeight =
        ScreenTools.screenHeight -
        ScreenTools.statusBarHeight -
        ScreenTools.bottomBarHeight -
        117.w; // 默认高度

    if (renderBox != null) {
      canvasWidth = renderBox.size.width;
      canvasHeight = renderBox.size.height;
    }

    // 根据类型确定宽高
    double finalWidth = 200.w; // 默认宽度
    double finalHeight = 200.w; // 默认高度

    // 如果是图片类型，根据图片实际尺寸计算
    if (type == ElementType.image) {
      if (imagePath.isEmpty) {
        return;
      }
      final imageSize = await _getImageSize(imagePath);
      if (imageSize != null) {
        final fitSize = _calculateFitSize(imageSize, canvasWidth, canvasHeight);
        finalWidth = fitSize.width;
        finalHeight = fitSize.height;
        debugPrint('图片原始尺寸: ${imageSize.width}x${imageSize.height}');
        debugPrint('适配后尺寸: $finalWidth x $finalHeight');
      }
    } else {
      // 文本类型，使用默认字体属性计算尺寸
      Size textSize = TextMeasureUtil.measureText(
        text: text,
        fontSize: 14.w,
        fontFamily: 'Courier', // 默认字体
        fontWeight: FontWeight.w500, // 默认字重
        letterSpacing: 0, // 默认字间距
        lineHeight: 1.0, // 默认行高
      );
      finalWidth = textSize.width;
      finalHeight = textSize.height;
    }

    // 计算子组件在画布中心的位置
    final centerX = (canvasWidth - finalWidth) / 2;
    final centerY = (canvasHeight - finalHeight) / 2;

    setState(() {
      boxes.add(
        EditBoxData(
          id: newId,
          text: type == ElementType.text ? text : '',
          position: Offset(centerX, centerY),
          type: type,
          imagePath: type == ElementType.image ? imagePath : '',
          width: finalWidth,
          height: finalHeight,
        ),
      );
    });

    // 自动选中新添加的元素
    _selectionController.select(newId);
  }

  void setActive(String? id) {
    debugPrint('设置激活状态: $id');
    if (id != null && id.isNotEmpty) {
      // 如果点击的是当前已激活的文本框，则取消激活
      if (_selectionController.selectedId == id) {
        _selectionController.deselect();
        debugPrint('取消激活状态: $id');
        _selectionController.updateToolBar(false);
      } else {
        // 否则激活该文本框
        _selectionController.select(id);
        debugPrint('激活新文本框: $id');
        _selectionController.updateToolBar(true);
      }
    } else {
      // 如果id为空，取消激活
      _selectionController.deselect();
      debugPrint('取消激活');
      _selectionController.updateToolBar(false);
    }
  }

  void deleteBox(String id) {
    setState(() {
      boxes.removeWhere((b) => b.id == id);
      if (_selectionController.selectedId == id) {
        _selectionController.deselect();
      }
    });
  }

  /// 显示文本输
  /// 入对话框并更新文本框内容
  void showTextInputDialog(String boxId) {
    // 查找对应的文本框
    final box = boxes.firstWhere((b) => b.id == boxId);

    SmartDialog.show(
      alignment: Alignment.bottomCenter,
      builder: (_) {
        return TextInputDialog(
          initialText: box.text,
          onConfirm: (newText) {
            // 更新文本框内容
            setState(() {
              box.text = newText;

              // 重新计算文本尺寸
              final textSize = TextMeasureUtil.measureText(
                text: newText,
                fontSize: box.fontSize,
                fontFamily: box.fontFamily,
                fontWeight: box.fontWeight,
                letterSpacing: box.fontSpace,
                lineHeight: box.lineHeight,
              );

              // 更新文本框尺寸
              box.width = textSize.width;
              box.height = textSize.height;
            });

            // 关闭对话框
            SmartDialog.dismiss();
          },
        );
      },
    );
  }

  void deleteSelectedBox() {
    final selectedId = _selectionController.selectedId;
    if (selectedId.isNotEmpty) {
      deleteBox(selectedId);
    }
  }

  // 处理指针按下事件
  void _handlePointerDown(PointerDownEvent event) {
    _gestureManager.handlePointerDown(
      event,
      boxes,
      _selectionController.selectedId,
      setActive,
    );
  }

  // 处理指针移动事件
  void _handlePointerMove(PointerMoveEvent event) {
    if (_gestureManager.handlePointerMove(
      event,
      boxes,
      _selectionController.selectedId,
    )) {
      setState(() {});
    }
  }

  // 处理指针抬起事件
  void _handlePointerUp(PointerUpEvent event) {
    _gestureManager.handlePointerUp(
      event,
      boxes,
      _selectionController.selectedId,
      (String? id) {
        if (id != null) {
          _selectionController.select(id);
          _selectionController.updateToolBar(true);
          debugPrint('激活元素: $id');
        } else {
          _selectionController.deselect();
          _selectionController.updateToolBar(false);
          debugPrint('取消激活');
        }
      },
    );
  }

  // 处理指针取消事件
  void _handlePointerCancel(PointerCancelEvent event) {
    _gestureManager.handlePointerCancel(event);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 监听删除标记
      if (_selectionController.shouldDelete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          deleteSelectedBox();
          _selectionController.clearDeleteFlag();
        });
      }

      // 监听添加标记
      if (_selectionController.shouldAdd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          addBox(type: ElementType.text);
          _selectionController.clearAddFlag();
        });
      }

      // 监听添加图片标记
      if (_selectionController.shouldAddImage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          addBox(
            type: ElementType.image,
            imagePath: _selectionController.imagePath,
            // width 和 height 不传，会根据图片自动计算
          );
          _selectionController.clearAddImageFlag();
        });
      }

      return Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 未选中的文本框（先渲染，在底层）
            ...boxes
                .where((box) => !_selectionController.isSelected(box.id))
                .map(
                  (box) => EditContentBox(
                    key: ValueKey(box.id),
                    data: box,
                    isActive: false,
                  ),
                ),

            // 选中的文本框（后渲染，在最上层）
            ...boxes
                .where((box) => _selectionController.isSelected(box.id))
                .map(
                  (box) => EditContentBox(
                    key: ValueKey(box.id),
                    data: box,
                    isActive: true,
                  ),
                ),
          ],
        ),
      );
    });
  }
}
