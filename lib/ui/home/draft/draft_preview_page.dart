import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';

class DraftPreviewPage extends StatelessWidget {
  DraftPreviewPage({super.key});
  final args = Get.arguments as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    final String canvasSize = args['canvasSize'] as String;
    final bool isLocal = args['isLocal'] as bool;
    final String imgPath = args['imgPath'] as String;
    final size = getCanvalsSize(canvasSize);
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
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
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              SizedBox(height: ScreenTools.statusBarHeight),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    CButton(
                      width: 51.w,
                      height: 51.w,
                      icon: Image.asset(
                        'assets/images/canvals/edit_back_icon.png',
                        width: 26.w,
                        height: 26.w,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (double, double) getCanvalsSize(String canvasSize) {
    final parts = canvasSize.split(':');
    final width = double.parse(parts[0]);
    final height = double.parse(parts[1]);

    final scaleW = ScreenTools.screenWidth / width;
    final scaleH = ScreenTools.screenHeight / height;
    final double minScale = math.min(scaleW, scaleH);
    final w = width * minScale;
    final h = height * minScale;
    return (w, h);
  }
}
