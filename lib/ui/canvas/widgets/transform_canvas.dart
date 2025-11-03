import 'package:flutter/material.dart';
import '../controllers/create_design_model.dart';
import '../edit_box/edit_content_box.dart';

/// TransformCanvas 组件：用于在外层渲染控制框
/// 将控制框从元素内部提取出来，避免受元素 Transform 影响
class TransformCanvas extends StatelessWidget {
  final List<EditBoxData> elements;
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 内容层
        child,

        // 控制框层（在最上层）
        if (selectedId != null && selectedId!.isNotEmpty)
          ..._buildControlLayer(),
      ],
    );
  }

  /// 构建控制框层
  List<Widget> _buildControlLayer() {
    final selectedElement = elements.firstWhere(
      (element) => element.id == selectedId,
      orElse: () => elements.first,
    );

    if (!selectedElement.visible) {
      return [];
    }

    final List<Widget> controls = [];

    // 渲染调整大小的控制点
    controls.addAll(_buildResizeHandles(selectedElement));

    // 渲染旋转按钮
    controls.add(_buildRotationButton(selectedElement));

    return controls;
  }

  /// 构建调整大小的控制点
  List<Widget> _buildResizeHandles(EditBoxData element) {
    final handlePositions = EditContentBox.getResizeHandleCenters(element);
    final handles = _getControlHandlesForType(element.type, element);
    const hitTestSize = 20.0;

    return handles.map((handleKey) {
      final position = handlePositions[handleKey];
      if (position == null) return const SizedBox.shrink();

      return Positioned(
        left: position.dx - hitTestSize / 2,
        top: position.dy - hitTestSize / 2,
        child: Container(
          width: hitTestSize,
          height: hitTestSize,
          alignment: Alignment.center,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 1),
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
        final totalHeight = element.height + EditContentBox.borderWidth * 2;
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
    const rotationButtonSize = 26.0;
    final buttonCenter = EditContentBox.getRotationButtonCenter(element);

    return Positioned(
      left: buttonCenter.dx - rotationButtonSize / 2,
      top: buttonCenter.dy - rotationButtonSize / 2,
      child: Image.asset(
        'assets/images/canvals/edit_rotation_icon.png',
        width: rotationButtonSize,
        height: rotationButtonSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
