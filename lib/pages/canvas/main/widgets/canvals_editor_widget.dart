import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../canvals_controller.dart';
import 'canvas_element_widget.dart';
import '../../gesture/element_gesture_manager.dart';
import '../../widgets/dialog/text_input_dialog.dart';
import '../../widgets/snap_lines_painter.dart';
import '../../utils/text_measure_util.dart';
import '../../history/index.dart';
import '../../model/index.dart';
import '../../draft/index.dart';

class CanvasEditorWidget extends StatefulWidget {
  final CanvasHistoryManager? historyManager;
  final VoidCallback? onContentChanged;
  final Matrix4 canvasMatrix;

  const CanvasEditorWidget({
    super.key,
    this.historyManager,
    this.onContentChanged,
    required this.canvasMatrix,
  });

  @override
  State<CanvasEditorWidget> createState() => CanvasEditorWidgetState();
}

class CanvasEditorWidgetState extends State<CanvasEditorWidget> {
  late CanvalsController _selectionController;
  final _gestureManager = ElementGestureManager(); // 画布手势管理

  CanvasHistoryManager? get historyManager => widget.historyManager; // 历史管理器

  RxList<CanvasElement> get boxes => _selectionController.elements;
  List<CanvasElement> get layers => List.from(boxes);
  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
    widget.onContentChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    _selectionController = Get.find<CanvalsController>();
    _gestureManager.historyManager = historyManager; // 设置历史管理器到手势管理器
  }

  /// 重新排序图层
  void reorderLayers(int oldIndex, int newIndex) {
    // 检查边界
    if (boxes.isEmpty ||
        oldIndex < 0 ||
        oldIndex >= boxes.length ||
        newIndex < 0 ||
        newIndex >= boxes.length) {
      AppLogger.info(
        '警告: 图层重排序索引越界: oldIndex=$oldIndex, newIndex=$newIndex, boxes.length=${boxes.length}',
      );
      return;
    }

    final oldOrder = boxes.map((box) => box.id).toList();
    setState(() {
      final item = boxes.removeAt(oldIndex);
      boxes.insert(newIndex, item);
    });
    final newOrder = boxes.map((box) => box.id).toList();

    // 记录命令
    if (historyManager != null && oldOrder.toString() != newOrder.toString()) {
      historyManager!.executeCommand(
        ReorderLayersCommand(
          boxes: boxes,
          oldOrder: oldOrder,
          newOrder: newOrder,
        ),
      );
    }

    // 通知草稿管理器元素顺序已变更
    DraftManager().notifyElementsChanged();
  }

  Future<void> addShape(ElementType type, Offset center) async {
    String shapeName = '';
    double boxWidth = 150;
    double boxHeight = 150;

    if (type == ElementType.rectangle) {
      shapeName = '矩形';
    }

    if (type == ElementType.ellipse) {
      shapeName = '椭圆';
      boxWidth = 150;
      boxHeight = 87;
    }

    if (type == ElementType.line) {
      shapeName = '线条';
      boxWidth = 216;
      boxHeight = 20;
    }

    final newId = _selectionController.generateId();

    final elementPos = Offset(
      center.dx - boxWidth / 2,
      center.dy - boxHeight / 2,
    );

    final newElement = CanvasElement(
      id: newId,
      text: shapeName,
      x: elementPos.dx,
      y: elementPos.dy,
      type: type,
      width: boxWidth,
      height: boxHeight,
    );

    setState(() {
      boxes.add(newElement);
    });

    if (historyManager != null) {
      historyManager!.executeCommand(AddElementCommand(boxes, newElement));
    }
    _selectionController.select(newId);
  }

  Future<void> addBox({
    required ElementType type,
    required Offset center,
    String text = '',
    String filePath = '',
  }) async {
    final newId = _selectionController.generateId();

    _selectionController.center = center;

    // 根据类型确定宽高
    double finalWidth = 200; // 默认宽度
    double finalHeight = 200; // 默认高度

    // 如果是图片类型，根据图片实际尺寸计算
    final imgW = _selectionController.imageWidth;
    final imgH = _selectionController.imageHeight;

    final canvalsW = _selectionController.canvalsWidth;
    final canvalsH = _selectionController.canvalsHeight;

    if (type == ElementType.image) {
      if (canvalsW > canvalsH) {
        if (imgW > imgH) {
          finalWidth = canvalsW * 0.6;
          finalHeight = finalWidth * (imgH / imgW);
        } else {
          finalHeight = canvalsH * 0.6;
          finalWidth = finalHeight * (imgW / imgH);
        }
      } else {
        finalWidth = canvalsW * 0.6;
        finalHeight = finalWidth * (imgH / imgW);
        if (finalHeight > canvalsH) {
          finalHeight = canvalsH * 0.6;
          finalWidth = finalHeight * (imgW / imgH);
        }
      }
    } else {
      // 文本类型，使用默认字体属性计算尺寸
      Size textSize = TextMeasureUtil.measureText(text: text);
      finalWidth = textSize.width;
      finalHeight = textSize.height;
    }

    // 获取屏幕中心在画布坐标中的位置（考虑平移和缩放）
    final centerX = center.dx - finalWidth / 2;
    final centerY = center.dy - finalHeight / 2;

    final newElement = CanvasElement(
      id: newId,
      text: type == ElementType.text ? text : '',
      x: centerX,
      y: centerY,
      type: type,
      filePath: filePath,
      width: finalWidth,
      height: finalHeight,
    );

    setState(() {
      boxes.add(newElement);
    });

    // 记录命令
    if (historyManager != null) {
      historyManager!.executeCommand(AddElementCommand(boxes, newElement));
    }

    // 自动选中新添加的元素
    _selectionController.select(newId);

    // 通知草稿管理器元素已添加
    DraftManager().notifyElementsChanged();
  }

  void setActive(String? id) {
    AppLogger.info('元素设置激活状态: $id');
    if (id != null && id.isNotEmpty) {
      // 如果点击的是当前已激活的文本框，则取消激活
      if (_selectionController.selectedId == id) {
        _selectionController.deselect();
        AppLogger.info('元素取消激活状态: $id');
        _selectionController.updateToolBar(false);
      } else {
        // 否则激活该文本框
        _selectionController.select(id);
        AppLogger.info('激活新文本框: $id');
        _selectionController.updateToolBar(true);
      }
    } else {
      // 如果id为空，取消激活
      _selectionController.deselect();
      AppLogger.info('取消激活: $id');
      _selectionController.updateToolBar(false);
    }
  }

  void deleteBox(String id) {
    // 检查元素是否存在
    final elementIndex = boxes.indexWhere((b) => b.id == id);
    if (elementIndex == -1) {
      AppLogger.info('警告: 尝试删除不存在的元素: $id');
      return;
    }

    final element = boxes[elementIndex];
    final clonedElement = CanvasElementClone.clone(element);

    setState(() {
      boxes.removeWhere((b) => b.id == id);
      if (_selectionController.selectedId == id) {
        _selectionController.deselect();
      }
      _gestureManager.clearInteractionState(id);
    });

    // 记录命令
    if (historyManager != null) {
      historyManager!.executeCommand(
        DeleteElementCommand(boxes, clonedElement),
      );
    }

    // 通知草稿管理器元素已删除
    DraftManager().notifyElementsChanged();
  }

  /// 显示文本输
  /// 入对话框并更新文本框内容
  void showTextInputDialog(String boxId) {
    // 查找对应的文本框
    final boxIndex = boxes.indexWhere((b) => b.id == boxId);
    if (boxIndex == -1) {
      AppLogger.info('警告: 尝试编辑不存在的文本框: $boxId');
      return;
    }

    final box = boxes[boxIndex];
    final oldText = box.text;
    final oldHeight = box.height;

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
              // 使用当前宽度来保持多行状态（如果已经是多行）
              final textSize = TextMeasureUtil.measureTextWithWidth(
                text: newText,
                fontSize: box.fontSize,
                fontFamily: box.familyKey,
                letterSpacing: box.fontSpace,
                lineHeight: box.lineHeight,
                maxWidth: box.width,
              );

              // 保持宽度不变，只更新高度
              // box.width 保持不变，这样多行文本仍然是多行
              box.height = textSize.height;
            });

            // 记录命令
            if (historyManager != null && oldText != newText) {
              historyManager!.executeCommand(
                UpdateTextCommand(
                  boxes: boxes,
                  elementId: boxId,
                  oldText: oldText,
                  newText: newText,
                  oldHeight: oldHeight,
                  newHeight: box.height,
                ),
              );
            }

            // 关闭对话框
            SmartDialog.dismiss();
          },
        );
      },
    );
  }

  /// 复制文本组件：克隆当前选中的文本元素，生成新 id 并偏移位置后加入画布
  void copyTextElement(CanvasElement source) {
    final cloned = CanvasElementClone.clone(source);
    cloned.id = _selectionController.generateId();
    cloned.x = source.x + 10;
    cloned.y = source.y + 10;

    setState(() {
      boxes.add(cloned);
    });

    if (historyManager != null) {
      historyManager!.executeCommand(AddElementCommand(boxes, cloned));
    }

    _selectionController.select(cloned.id);
    DraftManager().notifyElementsChanged();
  }

  void deleteSelectedBox() {
    final selectedId = _selectionController.selectedId;
    if (selectedId.isNotEmpty) {
      deleteBox(selectedId);
    }
  }

  void handlePointerDown(PointerDownEvent event) {
    _gestureManager.updateCanvasMatrix(widget.canvasMatrix);

    AppLogger.info('_selectionController-${_selectionController.selectedId}');

    _gestureManager.handlePointerDown(
      event,
      boxes,
      _selectionController.selectedId,
    );
  }

  // 处理指针移动事件（改为公有方法，供外部调用）
  void handlePointerMove(PointerMoveEvent event) {
    _gestureManager.updateCanvasMatrix(widget.canvasMatrix);
    if (_gestureManager.handlePointerMove(
      event,
      boxes,
      _selectionController.selectedId,
    )) {
      setState(() {});
    }
  }

  // 处理指针抬起事件（改为公有方法，供外部调用）
  void handlePointerUp(PointerUpEvent event) {
    _gestureManager.updateCanvasMatrix(widget.canvasMatrix);
    _gestureManager.handlePointerUp(
      event,
      boxes,
      _selectionController.selectedId,
    );
  }

  // 处理指针取消事件（改为公有方法，供外部调用）
  void handlePointerCancel(PointerCancelEvent event) {
    _gestureManager.updateCanvasMatrix(widget.canvasMatrix);
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
          addBox(type: ElementType.text, center: _selectionController.center);
          _selectionController.clearAddFlag();
        });
      }

      // 监听添加图片标记
      if (_selectionController.shouldAddImage) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          addBox(
            type: ElementType.image,
            center: _selectionController.center,
            filePath: _selectionController.filePath,
          );
          _selectionController.clearAddImageFlag();
        });
      }

      // 仅负责渲染内容层，裁剪和控制层在外部处理
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 未选中的元素（先渲染，在底层）
          ...boxes
              .where((box) => !_selectionController.isSelected(box.id))
              .map(
                (box) => CanvasElementWidget(key: ValueKey(box.id), data: box),
              ),

          // 选中的元素（后渲染，在最上层）
          ...boxes
              .where((box) => _selectionController.isSelected(box.id))
              .map(
                (box) => CanvasElementWidget(key: ValueKey(box.id), data: box),
              ),

          // 吸附参考线（最上层）
          if (_gestureManager.currentSnapLines.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: SnapLinesPainter(
                  snapLines: _gestureManager.currentSnapLines,
                ),
              ),
            ),
        ],
      );
    });
  }

  /// 撤销操作
  void undo() {
    historyManager?.undo();
    setState(() {});
  }

  /// 重做操作
  void redo() {
    historyManager?.redo();
    setState(() {});
  }
}
