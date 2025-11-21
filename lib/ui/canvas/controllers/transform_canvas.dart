import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../model/index.dart';

/// TransformCanvas 组件：用于在外层渲染控制框，将控制框从元素内部提取出来，避免受元素 Transform 影响
class TransformCanvas extends StatelessWidget {
  final vm.Matrix4 canvasMatrix;
  final List<CanvasElement> elements;
  final String? selectedId;

  const TransformCanvas({
    super.key,
    required this.canvasMatrix,
    required this.elements,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedId != null && selectedId!.isNotEmpty;
    if (!hasSelection || elements.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true,
      child: SizedBox.expand(
        child: Stack(clipBehavior: Clip.none, children: _buildControlLayer()),
      ),
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

    final handles = MatrixUtilsXGesture.controlHandlesForType(
      element.type,
      element,
    );

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
    return MatrixUtilsX.worldCorners(e, canvasMatrix);
  }
}
