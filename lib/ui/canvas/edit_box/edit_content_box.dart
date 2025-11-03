import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../controllers/create_design_model.dart';
import 'out_lined_text.dart';

class EditContentBox extends StatelessWidget {
  final EditBoxData data;
  final bool isActive;

  const EditContentBox({super.key, required this.data, required this.isActive});

  // 常量定义
  static const double hitTestSize = 20.0; // 控制点点击区域大小
  static const double rotationButtonSize = 26.0;
  static const double rotationButtonPadding = 15.0;
  static const double borderWidth = 3.0; // 边框宽度

  @override
  Widget build(BuildContext context) {
    // 如果元素不可见，返回空的 Container
    if (!data.visible) {
      return SizedBox.shrink();
    }

    return Positioned(
      left: data.position.dx,
      top: data.position.dy,
      child: Transform.rotate(
        angle: data.rotation,
        alignment: Alignment.center, // 围绕中心旋转
        child: Container(
          // 外层容器始终包含边框空间
          width: data.width + borderWidth * 2,
          height: data.height + borderWidth * 2,
          decoration: BoxDecoration(
            color: Colors.transparent,
            // 只有边框显隐变化，尺寸不变
            border: isActive
                ? Border.all(color: "#ff147EFF".color, width: borderWidth)
                : null,
          ),
          child: _buildContent(),
        ),
      ),
    );
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
          alignment: Alignment.topLeft,
          child: OutlinedText(
            text: data.text,
            textStyle: TextStyle(
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
            strokeWidth: data.borderWidth, // 描边宽度，需要自己计算：fontSize * 0.18
            strokeColor: data.borderColor.color,
            fillColor: data.fillColor.color,
            maxLines: null,
          ),
        );
    }
  }

  // 辅助方法：获取旋转按钮的全局位置（用于外部判断点击）
  static Offset getRotationButtonCenter(EditBoxData data) {
    // 旋转按钮在容器底部中心，有padding
    // 外层容器始终包含边框
    final totalWidth = data.width + borderWidth * 2;
    final totalHeight = data.height + borderWidth * 2;

    // 相对于容器中心的位置
    final buttonLocalX = 0.0; // 在中心的x坐标
    final buttonLocalY =
        totalHeight / 2 + rotationButtonPadding + rotationButtonSize / 2;

    // 应用旋转（围绕中心旋转）
    final cos = math.cos(data.rotation);
    final sin = math.sin(data.rotation);
    final rotatedX = buttonLocalX * cos - buttonLocalY * sin;
    final rotatedY = buttonLocalX * sin + buttonLocalY * cos;

    // 转换为全局坐标（容器中心 + 旋转后的偏移）
    final centerX = data.position.dx + totalWidth / 2;
    final centerY = data.position.dy + totalHeight / 2;
    return Offset(centerX + rotatedX, centerY + rotatedY);
  }

  // 辅助方法：获取调整大小控制点的全局位置
  static Map<String, Offset> getResizeHandleCenters(EditBoxData data) {
    // 外层容器始终包含边框
    final totalWidth = data.width + borderWidth * 2;
    final totalHeight = data.height + borderWidth * 2;

    // 控制点相对于容器左上角的位置
    final localPositions = {
      // 四个角点
      'top-left': Offset(0, 0), // 左上角
      'top-right': Offset(totalWidth - 4.5, 0), // 右上角
      'bottom-left': Offset(0, totalHeight - 4.5), // 左下角
      'bottom-right': Offset(totalWidth - 4.5, totalHeight - 4.5), // 右下角
      // 四个边中点
      'left': Offset(-1.5, totalHeight / 2 - 3), // 左边中点
      'right': Offset(totalWidth - 4.5, totalHeight / 2 - 3), // 右边中点
      'top': Offset(totalWidth / 2 - 3, -1.5), // 上边中点
      'bottom': Offset(totalWidth / 2 - 3, totalHeight - 4.5), // 下边中点
    };

    final cos = math.cos(data.rotation);
    final sin = math.sin(data.rotation);

    // 容器中心的全局坐标（包含边框）
    final centerX = data.position.dx + totalWidth / 2;
    final centerY = data.position.dy + totalHeight / 2;

    return localPositions.map((key, localPos) {
      // 相对于中心的坐标
      final relX = localPos.dx - totalWidth / 2;
      final relY = localPos.dy - totalHeight / 2;

      // 应用旋转
      final rotatedX = relX * cos - relY * sin;
      final rotatedY = relX * sin + relY * cos;

      // 转换为全局坐标
      return MapEntry(key, Offset(centerX + rotatedX, centerY + rotatedY));
    });
  }
}
