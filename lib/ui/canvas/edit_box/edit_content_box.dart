import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../controllers/create_design_model.dart';

class EditContentBox extends StatelessWidget {
  final EditBoxData data;
  final bool isActive;

  const EditContentBox({super.key, required this.data, required this.isActive});

  // 常量定义
  static const double hitTestSize = 20.0;
  static const double rotationButtonSize = 26.0;
  static const double rotationButtonPadding = 15.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 主要内容（包含文本框和控制点，参与旋转）
        Positioned(
          left: data.position.dx,
          top: data.position.dy,
          child: Transform.rotate(
            angle: data.rotation,
            alignment: Alignment.center, // 围绕中心旋转
            child: Container(
              width: data.width,
              height: data.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: isActive
                    ? Border.all(color: "#ff147EFF".color, width: 3)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 内容
                  _buildContent(),

                  // 调整大小的控制点
                  if (isActive) ..._getControlPoints(),
                ],
              ),
            ),
          ),
        ),

        // 旋转按钮（不参与旋转，单独定位）
        if (isActive) _buildRotationButton(),
      ],
    );
  }

  // 构建旋转按钮
  Widget _buildRotationButton() {
    final buttonCenter = getRotationButtonCenter(data);
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

  // 构建调整大小的圆点
  Widget _buildResizeHandle(String position) {
    Offset positionOffset =
        _calculateResizeHandlePositions(data.width, data.height)[position] ??
        Offset.zero;

    // 控制点位置使用相对定位（相对于 Stack）
    final adjustedPosition = Offset(
      positionOffset.dx - hitTestSize / 2,
      positionOffset.dy - hitTestSize / 2,
    );

    return Positioned(
      left: adjustedPosition.dx,
      top: adjustedPosition.dy,
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
  }

  // 计算调整大小控制点位置的函数
  Map<String, Offset> _calculateResizeHandlePositions(
    double width,
    double height,
  ) {
    return {
      // 四个角点
      'top-left': Offset(0, 0), // 左上角
      'top-right': Offset(width - 4.5, 0), // 右上角
      'bottom-left': Offset(0, height - 4.5), // 左下角
      'bottom-right': Offset(width - 4.5, height - 4.5), // 右下角
      // 四个边中点
      'left': Offset(-1.5, height / 2 - 3), // 左边中点
      'right': Offset(width - 4.5, height / 2 - 3), // 右边中点
      'top': Offset(width / 2 - 3, -1.5), // 上边中点
      'bottom': Offset(width / 2 - 3, height - 4.5), // 下边中点
    };
  }

  // 构建内容
  Widget _buildContent() {
    switch (data.type) {
      case ElementType.image:
        if (data.imagePath.isNotEmpty) {
          return ClipRect(
            child: Image.asset(
              data.imagePath,
              width: data.width,
              height: data.height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image, color: Colors.grey, size: 48),
            ),
          );
        }
      case ElementType.rectangle:
        return Container(
          width: data.width,
          height: data.height,
          decoration: BoxDecoration(
            color: data.fillColor.color,
            border: Border.all(
              color: data.borderColor.color,
              width: data.borderWidth,
            ),
            boxShadow: data.isShawOpen
                ? [
                    BoxShadow(
                      color: data.shawColor.color,
                      offset: Offset(data.shawX, data.shawY),
                      blurRadius: data.blurValue,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        );
      case ElementType.ellipse:
        return Container(
          width: data.width,
          height: data.height,
          decoration: BoxDecoration(
            color: data.fillColor.color,
            border: Border.all(
              color: data.borderColor.color,
              width: data.borderWidth,
            ),
            boxShadow: data.isShawOpen
                ? [
                    BoxShadow(
                      color: data.shawColor.color,
                      offset: Offset(data.shawX, data.shawY),
                      blurRadius: data.blurValue,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
            borderRadius: BorderRadius.all(
              Radius.elliptical(data.width / 2, data.height / 2),
            ),
          ),
        );
      case ElementType.line:
        return Center(
          child: Container(
            width: data.width,
            height: data.height - 18.5.w,
            decoration: BoxDecoration(
              color: data.fillColor.color,
              border: Border.all(
                color: data.borderColor.color,
                width: data.borderWidth,
              ),
              boxShadow: data.isShawOpen
                  ? [
                      BoxShadow(
                        color: data.shawColor.color,
                        offset: Offset(data.shawX, data.shawY),
                        blurRadius: data.blurValue,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      case ElementType.text:
        return Container(
          width: data.width,
          height: data.height,
          color: Colors.transparent,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              data.text,
              style: TextStyle(
                fontFamily: data.fontFamily,
                fontSize: data.fontSize,
                fontWeight: data.fontWeight,
                color: data.textColor.color,
                height: data.lineHeight,
                letterSpacing: data.fontSpace,
                shadows: data.isShawOpen
                    ? [
                        Shadow(
                          color: data.shawColor.color,
                          offset: Offset(data.shawX, data.shawY),
                          blurRadius: data.blurValue,
                        ),
                      ]
                    : [],
              ),
              textAlign: data.align,
            ),
          ),
        );
    }
  }

  List<Widget> _getControlPoints() {
    switch (data.type) {
      case ElementType.image:
      case ElementType.rectangle:
      case ElementType.ellipse:
        return [
          _buildResizeHandle('top-left'),
          _buildResizeHandle('top'),
          _buildResizeHandle('top-right'),
          _buildResizeHandle('right'),
          _buildResizeHandle('bottom-right'),
          _buildResizeHandle('bottom'),
          _buildResizeHandle('bottom-left'),
          _buildResizeHandle('left'),
        ];
      case ElementType.text:
        return [
          _buildResizeHandle('top-left'),
          _buildResizeHandle('top-right'),
          _buildResizeHandle('right'),
          _buildResizeHandle('bottom-right'),
          _buildResizeHandle('bottom-left'),
          _buildResizeHandle('left'),
        ];
      case ElementType.line:
        return [
          _buildResizeHandle('left'),
          _buildResizeHandle('top'),
          _buildResizeHandle('right'),
          _buildResizeHandle('bottom'),
        ];
    }
  }

  // 辅助方法：获取旋转按钮的全局位置（用于外部判断点击）
  static Offset getRotationButtonCenter(EditBoxData data) {
    // 旋转按钮在容器底部中心，有padding
    // 相对于容器中心的位置
    final buttonLocalX = 0.0; // 在中心的x坐标
    final buttonLocalY =
        data.height / 2 + rotationButtonPadding + rotationButtonSize / 2;

    // 应用旋转（围绕中心旋转）
    final cos = math.cos(data.rotation);
    final sin = math.sin(data.rotation);
    final rotatedX = buttonLocalX * cos - buttonLocalY * sin;
    final rotatedY = buttonLocalX * sin + buttonLocalY * cos;

    // 转换为全局坐标（容器中心 + 旋转后的偏移）
    final centerX = data.position.dx + data.width / 2;
    final centerY = data.position.dy + data.height / 2;
    return Offset(centerX + rotatedX, centerY + rotatedY);
  }

  // 辅助方法：获取调整大小控制点的全局位置
  static Map<String, Offset> getResizeHandleCenters(EditBoxData data) {
    // 控制点相对于容器左上角的位置
    final localPositions = {
      // 四个角点
      'top-left': Offset(0, 0), // 左上角
      'top-right': Offset(data.width - 4.5, 0), // 右上角
      'bottom-left': Offset(0, data.height - 4.5), // 左下角
      'bottom-right': Offset(data.width - 4.5, data.height - 4.5), // 右下角
      // 四个边中点
      'left': Offset(-1.5, data.height / 2 - 3), // 左边中点
      'right': Offset(data.width - 4.5, data.height / 2 - 3), // 右边中点
      'top': Offset(data.width / 2 - 3, -1.5), // 上边中点
      'bottom': Offset(data.width / 2 - 3, data.height - 4.5), // 下边中点
    };

    final cos = math.cos(data.rotation);
    final sin = math.sin(data.rotation);

    // 容器中心的全局坐标
    final centerX = data.position.dx + data.width / 2;
    final centerY = data.position.dy + data.height / 2;

    return localPositions.map((key, localPos) {
      // 相对于中心的坐标
      final relX = localPos.dx - data.width / 2;
      final relY = localPos.dy - data.height / 2;

      // 应用旋转
      final rotatedX = relX * cos - relY * sin;
      final rotatedY = relX * sin + relY * cos;

      // 转换为全局坐标
      return MapEntry(key, Offset(centerX + rotatedX, centerY + rotatedY));
    });
  }
}
