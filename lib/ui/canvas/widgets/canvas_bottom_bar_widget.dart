import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../utils/image_text_btn.dart';

/// 画布底部工具栏
class CanvasBottomBar extends StatelessWidget {
  final VoidCallback onLayerTap;
  final VoidCallback onAddImage;
  final VoidCallback onAddShape;
  final VoidCallback onAddText;
  final VoidCallback onSave;
  final VoidCallback? onExport;
  final GlobalKey? layerButtonKey;

  const CanvasBottomBar({
    super.key,
    required this.onLayerTap,
    required this.onAddImage,
    required this.onAddShape,
    required this.onAddText,
    required this.onSave,
    this.onExport,
    this.layerButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 66.w,
          width: ScreenTools.screenWidth,
          color: Colors.white,
          child: Row(
            children: [
              SizedBox(width: 21.w),
              Row(
                children: [
                  ImageTextBtn(
                    key: layerButtonKey,
                    imageUrl: 'assets/images/canvals/edit_tuceng_icon.png',
                    text: "图层",
                    spacing: 0,
                    imageSize: 32.w,
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12.w,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: onLayerTap,
                    direction: Axis.vertical,
                  ),
                  SizedBox(width: 22.w),
                  ImageTextBtn(
                    imageUrl: 'assets/images/canvals/edit_image_icon.png',
                    text: "加图",
                    spacing: 0,
                    imageSize: 32.w,
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12.w,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: onAddImage,
                    direction: Axis.vertical,
                  ),
                  SizedBox(width: 22.w),
                  ImageTextBtn(
                    imageUrl: 'assets/images/canvals/edit_shape_icon.png',
                    text: "形状",
                    spacing: 0,
                    imageSize: 32.w,
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12.w,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: onAddShape,
                    direction: Axis.vertical,
                  ),
                  SizedBox(width: 22.w),
                  ImageTextBtn(
                    imageUrl: 'assets/images/canvals/edit_text_icon.png',
                    text: "文字",
                    spacing: 0,
                    imageSize: 32.w,
                    textStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12.w,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: onAddText,
                    direction: Axis.vertical,
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              Row(
                children: [
                  CButton(
                    icon: Image.asset(
                      'assets/images/canvals/edit_save_icon.png',
                      width: 62.w,
                      height: 28.w,
                    ),
                    onPressed: onSave,
                  ),
                  SizedBox(width: 8.w),
                  CButton(
                    icon: Image.asset(
                      'assets/images/canvals/edit_export_icon.png',
                      width: 62.w,
                      height: 28.w,
                    ),
                    onPressed:
                        onExport ??
                        () {
                          debugPrint("edit_export_icon-------");
                        },
                  ),
                  SizedBox(width: 14),
                ],
              ),
            ],
          ),
        ),
    
        Container(
          color: Colors.white,
          height: ScreenTools.bottomBarHeight,
          width: ScreenTools.screenWidth,
        ),
      ],
    );
  }
}
