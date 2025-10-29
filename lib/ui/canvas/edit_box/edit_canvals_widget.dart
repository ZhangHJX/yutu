import 'dart:io';
import 'dart:ui' as ui;

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../controllers/canvals_controller.dart';
import '../widgets/dialog/canvals_shape_dialog.dart';
import '../controllers/create_design_model.dart';
import 'edit_content_box.dart';

class CanvasEditorWidget extends StatefulWidget {
  const CanvasEditorWidget({super.key});
  @override
  State<CanvasEditorWidget> createState() => CanvasEditorWidgetState();
}

class CanvasEditorWidgetState extends State<CanvasEditorWidget> {
  late CanvalsController _selectionController;
  final List<EditBoxData> boxes = [];

  // 拖动相关变量
  Offset? _dragStartPosition;
  Offset? _dragStartBoxPosition;

  // 点击检测变量
  bool _isClick = false;

  // 缩放相关变量
  double _cumulativeScale = 1.0; // 累积缩放比例
  Offset? _fixedScaleCenter; // 固定的缩放中心点（缩放开始时确定，不再改变）
  double _initialWidth = 300.0; // 初始宽度
  double _initialHeight = 200.0; // 初始高度
  bool _hasMoved = false; // 添加移动检测

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

    switch (shapeType) {
      case ShapeType.rectangle:
        elementType = ElementType.rectangle;
        shapeName = '矩形';
        break;
      case ShapeType.ellipse:
        elementType = ElementType.ellipse;
        shapeName = '椭圆';
        break;
      case ShapeType.line:
        elementType = ElementType.line;
        shapeName = '线条';
        break;
    }

    final newId = _selectionController.generateId();

    // 获取画布容器的实际尺寸
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    double canvasWidth = 300.0; // 默认宽度
    double canvasHeight = 200.0; // 默认高度

    if (renderBox != null) {
      canvasWidth = renderBox.size.width;
      canvasHeight = renderBox.size.height;
    } else {
      // 如果无法获取画布尺寸，使用屏幕尺寸作为备用方案
      final screenSize = MediaQuery.of(context).size;
      canvasWidth = screenSize.width;
      canvasHeight = screenSize.height;
    }

    // 计算子组件在画布中心的位置
    final centerX = canvasWidth / 2 - 150; // 文本框宽度的一半 (300/2)
    final centerY = canvasHeight / 2 - 100; // 文本框高度的一半 (200/2)

    setState(() {
      boxes.add(
        EditBoxData(
          id: newId,
          text: shapeName,
          position: Offset(centerX, centerY),
          type: elementType,
          width: 300.0,
          height: 200.0,
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
    double? width, // 改为可选参数
    double? height, // 改为可选参数
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
    double finalWidth = width ?? 200.w; // 默认宽度
    double finalHeight = height ?? 200.w; // 默认高度

    // 如果是图片类型，根据图片实际尺寸计算
    if (type == ElementType.image && imagePath.isNotEmpty) {
      final imageSize = await _getImageSize(imagePath);
      if (imageSize != null) {
        final fitSize = _calculateFitSize(imageSize, canvasWidth, canvasHeight);
        finalWidth = fitSize.width;
        finalHeight = fitSize.height;
        debugPrint('图片原始尺寸: ${imageSize.width}x${imageSize.height}');
        debugPrint('适配后尺寸: $finalWidth x $finalHeight');
      } else {
        // 如果获取失败，使用默认正方形尺寸
        debugPrint('无法获取图片尺寸，使用默认尺寸');
        finalWidth = 200.w;
        finalHeight = 200.w;
      }
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
        // 切换文本框时重置固定中心点，让新文本框有自己的缩放中心
        _fixedScaleCenter = null;
        debugPrint('激活新文本框: $id，重置缩放中心点');
        _selectionController.updateToolBar(true);
      }
    } else {
      // 如果id为空，取消激活
      _selectionController.deselect();
      // 取消激活时也重置中心点
      _fixedScaleCenter = null;
      debugPrint('取消激活，重置缩放中心点');

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

  void deleteSelectedBox() {
    final selectedId = _selectionController.selectedId;
    if (selectedId.isNotEmpty) {
      deleteBox(selectedId);
    }
  }

  // 处理缩放开始（同时处理拖动和缩放）
  void _handleScaleStart(ScaleStartDetails details) {
    final selectedId = _selectionController.selectedId;
    if (selectedId.isNotEmpty) {
      _hasMoved = false;
      _isClick = true;
      final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
      _cumulativeScale = 1.0; // 重置累积缩放

      // 只在第一次缩放时确定固定的中心点，之后不再改变
      if (_fixedScaleCenter == null) {
        _fixedScaleCenter = Offset(
          selectedBox.position.dx + selectedBox.width / 2,
          selectedBox.position.dy + selectedBox.height / 2,
        );
        _initialWidth = selectedBox.width;
        _initialHeight = selectedBox.height;
        debugPrint(
          '确定固定缩放中心点: $_fixedScaleCenter, 初始尺寸: ${_initialWidth}x${_initialHeight}',
        );
      }

      _dragStartPosition = details.focalPoint;
      _dragStartBoxPosition = selectedBox.position;
      debugPrint('开始缩放/拖动检测: $selectedId, 使用固定中心点: $_fixedScaleCenter');
    } else {
      // 没有选中元素时，重置所有状态
      _hasMoved = false;
      _isClick = true;
      _cumulativeScale = 1.0;
      _fixedScaleCenter = null;
      _dragStartPosition = null;
      _dragStartBoxPosition = null;
      debugPrint('没有选中元素，重置拖拽状态');
    }
  }

  // 处理缩放更新（同时处理拖动和缩放）
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final selectedId = _selectionController.selectedId;
    if (selectedId.isNotEmpty &&
        _dragStartPosition != null &&
        _dragStartBoxPosition != null) {
      // 检测是否有移动
      final delta = details.focalPoint - _dragStartPosition!;
      if (delta.distance > 3.0) {
        // 降低移动阈值，使拖拽更敏感
        _hasMoved = true;
        _isClick = false; // 有移动就不是点击
      }

      // 处理拖动（当缩放比例接近1.0时，认为是拖动）
      if (_hasMoved) {
        // 如果缩放比例接近1.0，认为是拖动操作
        if (details.scale >= 0.98 && details.scale <= 1.02) {
          final newPosition = _dragStartBoxPosition! + delta;

          setState(() {
            final selectedBox = boxes.firstWhere((box) => box.id == selectedId);
            selectedBox.position = newPosition;
          });

          debugPrint('拖拽更新: 新位置=$newPosition, 移动距离=${delta.distance}');
        }
      }

      // 处理缩放（当缩放比例明显偏离1.0时，认为是缩放操作）
      if (_hasMoved && (details.scale < 0.98 || details.scale > 1.02)) {
        // 累积缩放比例，使缩放更平滑流畅
        _cumulativeScale *= details.scale;
        _cumulativeScale = _cumulativeScale.clamp(0.1, 10.0); // 扩大缩放范围，使缩放更流畅

        setState(() {
          final selectedBox = boxes.firstWhere((box) => box.id == selectedId);

          // 使用固定的缩放中心点
          if (_fixedScaleCenter != null) {
            // 使用初始尺寸和累积缩放比例计算新尺寸
            final newWidth = (_initialWidth * _cumulativeScale).clamp(
              50.0,
              1000.0,
            );
            final newHeight = (_initialHeight * _cumulativeScale).clamp(
              50.0,
              1000.0,
            );

            // 始终以固定的文本框中心为锚点进行缩放
            // 计算新的位置，使固定中心点保持不变
            final newPosition = Offset(
              _fixedScaleCenter!.dx - newWidth / 2, // 固定中心点X - 新宽度的一半
              _fixedScaleCenter!.dy - newHeight / 2, // 固定中心点Y - 新高度的一半
            );

            // 更新文本框的位置和尺寸
            selectedBox.position = newPosition;
            selectedBox.width = newWidth;
            selectedBox.height = newHeight;

            debugPrint(
              '缩放更新: 累积缩放=$_cumulativeScale, 新尺寸=${newWidth}x${newHeight}, 固定中心点=$_fixedScaleCenter',
            );
          }
        });
      }
    }
  }

  // 处理缩放结束（同时处理拖动和缩放）
  void _handleScaleEnd(ScaleEndDetails details) {
    final selectedId = _selectionController.selectedId;
    if (selectedId.isNotEmpty) {
      // 如果是点击（没有移动且缩放比例接近1.0）
      if (_isClick && !_hasMoved) {
        debugPrint('检测到点击事件，但元素已选中，不处理');
      }

      _hasMoved = false;
      _isClick = false;
      _cumulativeScale = 1.0; // 重置累积缩放
      // 注意：不重置 _fixedScaleCenter，保持固定中心点
      _dragStartPosition = null;
      _dragStartBoxPosition = null;
      debugPrint('缩放/拖动结束，固定中心点保持: $_fixedScaleCenter');
    } else {
      // 没有选中元素时的点击处理
      if (_isClick && !_hasMoved) {
        debugPrint('检测到背景点击事件');
        // 这里不需要额外处理，因为背景的onTap会处理
      }

      _hasMoved = false;
      _isClick = false;
      _cumulativeScale = 1.0;
      _fixedScaleCenter = null;
      _dragStartPosition = null;
      _dragStartBoxPosition = null;
      debugPrint('没有选中元素，重置所有状态');
    }
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
          addBox(type: ElementType.text, width: 200.w, height: 100.w);
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

      return GestureDetector(
        onTap: () {
          // 点击空白区域取消选中状态
          debugPrint('点击背景，取消选中');
          _selectionController.deselect();
        },
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
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
                    onTap: () => setActive(box.id),
                    onDelete: () => deleteBox(box.id),
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
                    onTap: () => setActive(box.id),
                    onDelete: () => deleteBox(box.id),
                  ),
                ),
          ],
        ),
      );
    });
  }
}
