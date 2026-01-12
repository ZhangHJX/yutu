import 'package:flutter/material.dart';
import 'canvas_custom_listener.dart';
import '../pages/canvals/canvals_controller.dart';
import 'canvas_status_manager.dart';
import 'matrix_utils.dart';
import '../model/index.dart';

class CanvasPointerWrapper extends StatelessWidget {
  final Widget child;

  final CanvalsController canvalsController;
  final CanvasStatusManager canvasStatusManager;

  final GlobalKey canvasKey;
  final GlobalKey canvasContainerKey;

  const CanvasPointerWrapper({
    super.key,
    required this.child,
    required this.canvalsController,
    required this.canvasStatusManager,
    required this.canvasKey,
    required this.canvasContainerKey,
  });

  @override
  Widget build(BuildContext context) {
    return CanvasCustomListener(
      onTap: () {
        final element = MatrixUtilsXGesture.detectHitElement(
          canvalsController.currentPoint!,
          canvasContainerKey,
          canvalsController.elements,
          Size(canvalsController.canvalsWidth, canvalsController.canvalsHeight),
          canvalsController.canvasModel.transform,
        );
        if (element == null || element.id.isEmpty) {
          canvalsController.deselect();
          return;
        }

        if (canvalsController.isSelected(element.id) &&
            element.type == ElementType.text) {
          (canvasKey.currentState as dynamic)?.showTextInputDialog(element.id);
        } else {
          canvalsController.toggleSelection(element.id);
        }
      },
      onPointerDown: (event) {
        canvalsController.currentPoint = event;

        if (canvalsController.selectedId.isNotEmpty) {
          final localPos = MatrixUtilsX.canvasLocal(
            event.position,
            canvasContainerKey,
          );
          (canvasKey.currentState as dynamic)?.handlePointerDown(
            PointerDownEvent(position: localPos, pointer: event.pointer),
          );
        } else {
          canvasStatusManager.handlePointerDown(
            event,
            canvalsController.canvasModel.locked,
          );
        }
      },
      onPointerMove: (event) {
        if (canvalsController.selectedId.isNotEmpty) {
          final localPos = MatrixUtilsX.canvasLocal(
            event.position,
            canvasContainerKey,
          );
          (canvasKey.currentState as dynamic)?.handlePointerMove(
            PointerMoveEvent(
              position: localPos,
              pointer: event.pointer,
              delta: event.delta,
            ),
          );
        } else {
          canvasStatusManager.handlePointerMove(
            event,
            canvalsController.canvasModel.locked,
          );
        }
      },
      onPointerUp: (event) {
        final localPos = MatrixUtilsX.canvasLocal(
          event.position,
          canvasContainerKey,
        );
        if (canvalsController.selectedId.isNotEmpty) {
          (canvasKey.currentState as dynamic)?.handlePointerUp(
            PointerUpEvent(position: localPos, pointer: event.pointer),
          );
        } else {
          canvasStatusManager.handlePointerUp(
            event,
            canvalsController.canvasModel.locked,
          );
        }
      },
      onPointerCancel: (event) {
        if (canvalsController.selectedId.isNotEmpty) {
          final localPos = MatrixUtilsX.canvasLocal(
            event.position,
            canvasContainerKey,
          );
          (canvasKey.currentState as dynamic)?.handlePointerCancel(
            PointerCancelEvent(position: localPos, pointer: event.pointer),
          );
        } else {
          canvasStatusManager.handlePointerCancel(
            event,
            canvalsController.canvasModel.locked,
          );
        }
      },
      child: child,
    );
  }
}
