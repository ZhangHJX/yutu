import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/create_design_model.dart';
import '../utils/canvals_edit_box_util.dart';

/// TransformCanvas 组件：用于在外层渲染控制框，将控制框从元素内部提取出来，避免受元素 Transform 影响
class TransformBorderCanvas extends StatelessWidget {
  final List<EditBoxData> elements;
  final String? selectedId;
  final Widget child; // 内容层

  const TransformBorderCanvas({
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
    if (!selectedElement.isLock) {
      controls.addAll(_buildResizeHandles(selectedElement));
    }

    // 渲染旋转按钮
    if (!selectedElement.isLock) {
      controls.add(_buildRotationButton(selectedElement));
    }
    return controls;
  }

  /// 构建边框矩形
  Widget _buildBorder(EditBoxData element) {
    // 计算包含边框的总尺寸
    final totalWidth = element.width + editBorderWidth * 2;
    final totalHeight = element.height + editBorderWidth * 2;

    return Positioned(
      left: element.position.dx - editBorderWidth,
      top: element.position.dy - editBorderWidth,
      child: Transform.rotate(
        angle: element.rotation,
        alignment: Alignment.center,
        child: Container(
          width: totalWidth,
          height: totalHeight,
          decoration: BoxDecoration(
            color: Colors.transparent,
            // 只有边框显隐变化，尺寸不变
            border: Border.all(
              color: "#ff147EFF".color,
              width: editBorderWidth,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建调整大小的控制点
  List<Widget> _buildResizeHandles(EditBoxData element) {
    final handlePositions = CanvalsEditBoxUtil.getResizeHandleCenters(element);
    final handles = _getControlHandlesForType(element.type, element);

    return handles.map((handleKey) {
      final position = handlePositions[handleKey];
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

  /// 根据元素类型获取需要显示的控制点
  List<String> _getControlHandlesForType(
    ElementType type,
    EditBoxData element,
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

  /// 构建旋转按钮
  Widget _buildRotationButton(EditBoxData element) {
    final buttonCenter = CanvalsEditBoxUtil.getRotationButtonCenter(element);
    return Positioned(
      left: buttonCenter.dx - rotationButtonSize / 2,
      top: buttonCenter.dy - rotationButtonSize / 2,
      // child: const Icon(Icons.rotate_right, color: Colors.white, size: 16),
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
}
