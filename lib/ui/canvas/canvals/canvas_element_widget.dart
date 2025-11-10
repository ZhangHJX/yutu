import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/create_design_model.dart';
import 'out_lined_text.dart';

class CanvasElementWidget extends StatelessWidget {
  final CanvasElement data;
  final bool isActive;

  const CanvasElementWidget({super.key, required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: data.position.dx,
      top: data.position.dy,
      child: Transform.rotate(
        angle: data.rotation,
        alignment: Alignment.center, // 围绕中心旋转
        child: SizedBox(
          // 外层容器始终包含边框空间
          width: data.width,
          height: data.height,
          child: data.visible ? _buildContent() : null,
        ),
      ),
    );
  }

  // 构建内容
  Widget _buildContent() {
    switch (data.type) {
      case ElementType.image:
        return ClipRect(
          child: Opacity(
            opacity: data.imageAlpha,
            child: Image.asset(
              data.imagePath,
              width: data.width,
              height: data.height,
              fit: BoxFit.cover,
            ),
          ),
        );
      case ElementType.rectangle:
        return Opacity(
          opacity: data.fillAlpha,
          child: Container(
            width: data.width,
            height: data.height,
            decoration: BoxDecoration(
              color: data.fillColor.color,
              border: Border.all(
                color: data.borderColor.color.withValues(alpha: data.fillAlpha),
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
      case ElementType.ellipse:
        return Opacity(
          opacity: data.fillAlpha,
          child: Container(
            width: data.width,
            height: data.height,
            decoration: BoxDecoration(
              color: data.fillColor.color,
              border: Border.all(
                color: data.borderColor.color.withValues(
                  alpha: data.borderAlpha,
                ),
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
          ),
        );
      case ElementType.line:
        return Center(
          child: Opacity(
            opacity: data.fillAlpha,
            child: Container(
              width: data.width,
              height: data.height - 18.5.w,
              decoration: BoxDecoration(
                color: data.fillColor.color,
                border: Border.all(
                  color: data.borderColor.color.withValues(
                    alpha: data.borderAlpha,
                  ),
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
              color: data.textColor.color.withValues(alpha: data.textAlpha),
              height: data.lineHeight,
              letterSpacing: data.fontSpace,
              shadows: data.isShawOpen
                  ? [
                      Shadow(
                        color: data.shawColor.color.withValues(
                          alpha: data.shawAlpha,
                        ),
                        offset: Offset(data.shawX, data.shawY),
                        blurRadius: data.blurValue,
                      ),
                    ]
                  : [],
            ),
            textAlign: data.align,
            strokeWidth: data.borderWidth, // 描边宽度，需要自己计算：fontSize * 0.18
            strokeColor: data.borderColor.color.withValues(
              alpha: data.borderAlpha,
            ),
            fillColor: data.textColor.color.withValues(alpha: data.textAlpha),
            maxLines: null,
          ),
        );
    }
  }
}
