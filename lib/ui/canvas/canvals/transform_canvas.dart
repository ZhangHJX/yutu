import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/index.dart';

/// TransformCanvas 组件：用于在外层渲染控制框，将控制框从元素内部提取出来，避免受元素 Transform 影响
class TransformCanvas extends StatelessWidget {
  final List<CanvasElement> elements;
  final String? selectedId;
  final Widget child; // 内容层

  const TransformCanvas({
    super.key,
    required this.elements,
    this.selectedId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selectedId != null && selectedId!.isNotEmpty);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child, // 内容层
        if (isSelected) ..._buildControlLayer(), // 控制框层（在最上层）
      ],
    );
  }

  /// 构建控制框层
  List<Widget> _buildControlLayer() {
    final selectedElement = elements.firstWhere(
      (element) => element.id == selectedId,
      orElse: () => elements.first,
    );
    final List<Widget> controls = [];

    // 渲染边框矩形（在最底层）
    controls.add(_buildBorder(selectedElement));

    // 渲染调整大小的控制点
    if (!selectedElement.hidden) {
      controls.addAll(_buildResizeHandles(selectedElement));
    }

    // 渲染旋转按钮
    if (!selectedElement.hidden) {
      controls.add(_buildRotationButton(selectedElement));
    }
    return controls;
  }

  /// 构建边框矩形
  Widget _buildBorder(CanvasElement element) {
    final corners = _worldCorners(element);
    final tl = corners[0];
    final tr = corners[1];
    final br = corners[2];
    final bl = corners[3];

    final minX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a < b ? a : b);
    final maxX = [tl.dx, tr.dx, br.dx, bl.dx].reduce((a, b) => a > b ? a : b);
    final minY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a < b ? a : b);
    final maxY = [tl.dy, tr.dy, br.dy, bl.dy].reduce((a, b) => a > b ? a : b);

    final width = maxX - minX;
    final height = maxY - minY;

    return Positioned(
      left: minX - editBorderWidth,
      top: minY - editBorderWidth,
      child: Container(
        width: width + editBorderWidth * 2,
        height: height + editBorderWidth * 2,
        decoration: BoxDecoration(
          color: Colors.transparent,
          // 只有边框显隐变化，尺寸不变
          border: Border.all(color: "#ff147EFF".color, width: editBorderWidth),
        ),
      ),
    );
  }

  /// 构建调整大小的控制点
  List<Widget> _buildResizeHandles(CanvasElement element) {
    final corners = _worldCorners(element);
    final tl = corners[0];
    final tr = corners[1];
    final br = corners[2];
    final bl = corners[3];

    final centers = <String, Offset>{
      'top-left': tl,
      'top-right': tr,
      'bottom-right': br,
      'bottom-left': bl,
      'top': Offset((tl.dx + tr.dx) / 2, (tl.dy + tr.dy) / 2),
      'right': Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2),
      'bottom': Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2),
      'left': Offset((bl.dx + tl.dx) / 2, (bl.dy + tl.dy) / 2),
    };

    final handles = _getControlHandlesForType(element.type, element);

    return handles.map((handleKey) {
      final position = centers[handleKey];
      if (position == null) return const SizedBox.shrink();

      return Positioned(
        left: position.dx - editHitCircleSize / 2,
        top: position.dy - editHitCircleSize / 2,
        child: Container(
          width: editHitCircleSize,
          height: editHitCircleSize,
          alignment: Alignment.center,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 构建旋转按钮
  Widget _buildRotationButton(CanvasElement element) {
    final corners = _worldCorners(element);
    final br = corners[2];
    final bl = corners[3];
    final bottomCenter = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);

    // 向外偏移 rotationButtonPadding（这里简单按垂直方向偏移）
    final buttonCenter =
        bottomCenter +
        Offset(0, rotationButtonPadding + rotationButtonSize / 2);

    return Positioned(
      left: buttonCenter.dx - rotationButtonSize / 2,
      top: buttonCenter.dy - rotationButtonSize / 2,
      child: Image.asset(
        'assets/images/canvals/edit_rotation_icon.png',
        width: rotationButtonSize,
        height: rotationButtonSize,
        fit: BoxFit.contain,
        // 确保图片不旋转
        alignment: Alignment.center,
      ),
    );
  }

  List<Offset> _worldCorners(CanvasElement e) {
    // 确保每次使用最新的元素变换矩阵
    // 新增元素（例如通过 addShape）时，外部可能还没有调用 updateMatrix4，
    // 会导致编辑框位置和内容不一致，这里统一刷新一次。
    e.updateMatrix4();
    // TransformCanvas 在画布内部，所以 canvasMatrix 可以先用 identity
    return MatrixUtilsX.worldCorners(e, Matrix4.identity());
  }

  /// 根据元素类型获取需要显示的控制点
  List<String> _getControlHandlesForType(
    ElementType type,
    CanvasElement element,
  ) {
    switch (type) {
      case ElementType.image:
      case ElementType.rectangle:
      case ElementType.ellipse:
        return [
          'top-left',
          'top',
          'top-right',
          'right',
          'bottom-right',
          'bottom',
          'bottom-left',
          'left',
        ];
      case ElementType.text:
        final totalHeight = element.height + editBorderWidth * 2;
        if (totalHeight < 25.0) {
          return ['bottom-right'];
        }
        return [
          'top-left',
          'top-right',
          'right',
          'bottom-right',
          'bottom-left',
          'left',
        ];
      case ElementType.line:
        return ['left', 'top', 'right', 'bottom'];
    }
  }
}
