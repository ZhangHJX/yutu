import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/pages/utils/file/index.dart';
import 'canvas_text_widget.dart';
import '../../../model/index.dart';
import 'dart:io';

class CanvasElementWidget extends StatelessWidget {
  final CanvasElement data;
  const CanvasElementWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    data.updateMatrix4();
    final scaledWidth = data.width.w;
    final scaledHeight = data.height.w;
    return Transform(
      transform: data.transform,
      alignment:
          Alignment.topLeft, // Matrix 已经把原点移到了元素左上角，这里用 topLeft 避免再次做居中偏移
      child: SizedBox(
        width: scaledWidth,
        height: scaledHeight,
        child: data.hidden ? null : _buildContent(),
      ),
    );
  }

  // 构建内容
  Widget _buildContent() {
    switch (data.type) {
      case ElementType.image:
        return Opacity(
          opacity: data.fileAlpha,
          child: Image.file(
            File(PickerImageManager.loadCanvalsImage(data.filePath)),
            width: data.width.w,
            height: data.height.w,
            fit: BoxFit.fill,
          ),
        );
      case ElementType.rectangle:
        return Opacity(
          opacity: data.fillAlpha,
          child: Container(
            width: data.width.w,
            height: data.height.w,
            decoration: BoxDecoration(
              color: data.fillColor.color.withValues(alpha: data.fillAlpha),
              border: Border.all(
                color: data.borderColor.color.withValues(
                  alpha: data.borderAlpha,
                ),
                width: data.borderWidth.toDouble(),
              ),
              boxShadow: data.isShawOpen
                  ? [
                      BoxShadow(
                        color: data.shawColor.color.withValues(
                          alpha: data.shawAlpha,
                        ),
                        offset: Offset(data.shawX, data.shawY),
                        blurRadius: data.blurValue,
                        // spreadRadius: 0,
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
            width: data.width.w,
            height: data.height.w,
            decoration: BoxDecoration(
              color: data.fillColor.color,
              border: Border.all(
                color: data.borderColor.color.withValues(
                  alpha: data.borderAlpha,
                ),
                width: data.borderWidth.toDouble(),
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
              width: data.width.w,
              height: data.height.w - 18.5.w,
              decoration: BoxDecoration(
                color: data.fillColor.color,
                border: Border.all(
                  color: data.borderColor.color.withValues(
                    alpha: data.borderAlpha,
                  ),
                  width: data.borderWidth.toDouble(),
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
          width: data.width.w,
          height: data.height.w,
          color: Colors.transparent,
          alignment: Alignment.topLeft,
          child: CanvasTextWidget(
            text: data.text,
            textStyle: TextStyle(
              fontFamily: data.familyKey,
              fontSize: data.fontSize,
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
            strokeWidth: data.borderWidth.toDouble(),
            strokeColor: data.borderWidth > 0
                ? data.borderColor.color.withValues(alpha: data.borderAlpha)
                : Colors.transparent,
            fillColor: data.textColor.color.withValues(alpha: data.textAlpha),
            maxLines: null,
          ),
        );
    }
  }
}
