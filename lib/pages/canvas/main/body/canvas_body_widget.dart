import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../../gesture/index.dart';
import '../../history/index.dart';
import 'canvals_editor_widget.dart';
import 'transform_canvas.dart';
import '../canvals_controller.dart';

/// 画布区域独立 Widget：包含手势包装、画布内容、截图、变换与控制框层

class CanvasBodyWidget extends StatelessWidget {
  final CanvalsController canvalsController;
  final CanvasStatusManager canvasStatusManager;
  final GlobalKey<CanvasEditorWidgetState> canvasKey;
  final GlobalKey canvasContainerKey;
  final VoidCallback onTap;
  final ScreenshotController screenshotController;
  final CanvasHistoryManager? historyManager;
  final VoidCallback? onContentChanged;

  const CanvasBodyWidget({
    super.key,
    required this.canvalsController,
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
      canvalsController: canvalsController,
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
            canvalsController.getCanvalsSize(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final canvasContent = Screenshot(
              controller: screenshotController,
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      key: canvasContainerKey,
                      width: canvalsController.canvalsWidth,
                      height: canvalsController.canvalsHeight,
                      color: canvalsController.canvasModel.fillColor.color
                          .withValues(
                            alpha: canvalsController.canvasModel.fillAlpha,
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
                            canvalsController: canvalsController,
                            historyManager: historyManager,
                            onContentChanged: onContentChanged,
                            canvasMatrix:
                                canvalsController.canvasModel.transform,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            final boxes = canvalsController.elements;
            return Center(
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform(
                      transform: canvalsController.canvasModel.transform,
                      alignment: Alignment.topLeft,
                      child: canvasContent,
                    ),
                    Obx(
                      () => TransformCanvas(
                        elements: boxes,
                        selectedId: canvalsController.selectedId,
                        canvasMatrix: canvalsController.canvasModel.transform,
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
