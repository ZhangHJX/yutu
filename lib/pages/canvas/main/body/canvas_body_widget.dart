import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../../gesture/index.dart';
import '../../history/index.dart';
import 'canvals_editor_widget.dart';
import 'transform_canvas.dart';
import '../canvals_controller.dart';

/// 画布区域独立 Widget：包含手势包装、画布内容、截图、变换与控制框层
class CanvasBodyWidget extends AutoGetView<CanvalsController> {
  final CanvasStatusManager canvasStatusManager;
  final GlobalKey<CanvasEditorWidgetState> canvasKey;
  final GlobalKey canvasContainerKey;
  final VoidCallback onTap;
  final ScreenshotController screenshotController;
  final CanvasHistoryManager? historyManager;
  final VoidCallback? onContentChanged;

  const CanvasBodyWidget({
    super.key,
    required this.canvasStatusManager,
    required this.canvasKey,
    required this.canvasContainerKey,
    required this.onTap,
    required this.screenshotController,
    this.historyManager,
    this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CanvasPointerWrapper(
      canvalsController: logic,
      canvasStatusManager: canvasStatusManager,
      canvasKey: canvasKey,
      canvasContainerKey: canvasContainerKey,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: "#F6F2FB".color,
        child: LayoutBuilder(
          builder: (context, constraints) {
            logic.getCanvalsSize(constraints.maxWidth, constraints.maxHeight);
            final canvasContent = Screenshot(
              controller: screenshotController,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      key: canvasContainerKey,
                      width: logic.canvalsWidth,
                      height: logic.canvalsHeight,
                      color: logic.canvasModel.fillColor.color.withValues(
                        alpha: logic.canvasModel.fillAlpha,
                      ),
                    ),
                    Positioned.fill(
                      child: OverflowBox(
                        minWidth: 0,
                        minHeight: 0,
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        alignment: Alignment.topLeft,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: CanvasEditorWidget(
                            key: canvasKey,
                            historyManager: historyManager,
                            onContentChanged: onContentChanged,
                            canvasMatrix: logic.canvasModel.transform,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            final boxes = logic.elements;
            return Center(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform(
                      transform: logic.canvasModel.transform,
                      alignment: Alignment.topLeft,
                      child: canvasContent,
                    ),
                    Obx(
                      () => TransformCanvas(
                        elements: boxes,
                        selectedId: logic.selectedId,
                        canvasMatrix: logic.canvasModel.transform,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
