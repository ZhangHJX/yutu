import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../canvas/model/index.dart';
import 'dart:math' as math;
import 'dart:io';

class DraftPreviewWidget extends StatelessWidget {
  const DraftPreviewWidget({
    super.key,
    required this.canvasModel,
    required this.isLocal,
    required this.imgPath,
  });
  final CanvasModel canvasModel;
  final String imgPath;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    final size = getCanvalsSize();
    return Container(
      color: Colors.black,
      width: size.$1,
      height: size.$2,
      child: isLocal
          ? Image.file(File(imgPath), fit: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: imgPath,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    color: "#9082FF".color,
                  ),
                ),
              ),
            ),
    );
  }

  (double, double) getCanvalsSize() {
    final scaleW = ScreenTools.screenWidth / canvasModel.width;
    final scaleH = ScreenTools.screenHeight / canvasModel.height;
    final double minScale = math.min(scaleW, scaleH);
    final width = canvasModel.width * minScale;
    final height = canvasModel.height * minScale;
    return (width, height);
  }
}
