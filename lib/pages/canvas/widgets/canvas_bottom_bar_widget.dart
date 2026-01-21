import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 画布底部工具栏
class CanvasBottomBar extends StatelessWidget {
  final VoidCallback onLayerTap;
  final VoidCallback onAddImage;
  final VoidCallback onAddShape;
  final VoidCallback onAddText;
  final VoidCallback onSave;
  final VoidCallback onExport;

  const CanvasBottomBar({
    super.key,
    required this.onLayerTap,
    required this.onAddImage,
    required this.onAddShape,
    required this.onAddText,
    required this.onSave,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 66.w,
          width: ScreenTools.screenWidth,
          padding: EdgeInsets.only(left: 10.w, right: 10.w),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  getTextAndIconButton('图层', 'edit_tuceng_icon', onLayerTap),
                  getTextAndIconButton('加图', 'edit_image_icon', onAddImage),
                  getTextAndIconButton('形状', 'edit_shape_icon', onAddShape),
                  getTextAndIconButton('文字', 'edit_text_icon', onAddText),
                ],
              ),

              Row(
                children: [
                  CButton(
                    icon: Image.asset(
                      'assets/images/canvals/edit_save_icon.png',
                      width: 62.w,
                      height: 28.w,
                      fit: BoxFit.cover,
                    ),
                    onPressed: onSave,
                  ),

                  SizedBox(width: 4.w),

                  CButton(
                    icon: Image.asset(
                      'assets/images/canvals/edit_export_icon.png',
                      width: 62.w,
                      height: 28.w,
                      fit: BoxFit.cover,
                    ),
                    onPressed: onExport,
                  ),
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

  Widget getTextAndIconButton(
    String title,
    String imgName,
    VoidCallback onTap,
  ) {
    return CButton(
      // backgroundColor: randomColor(),
      iconPosition: CIconPosition.top,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      text: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF9E9E9E),
          fontSize: 12.w,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Image.asset(
        'assets/images/canvals/$imgName.png',
        width: 32.w,
        height: 32.w,
      ),
      onPressed: onTap,
    );
  }
}
