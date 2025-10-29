import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 画布顶部应用栏
class CanvasAppBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const CanvasAppBar({super.key, this.onBack, this.onUndo, this.onRedo});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: SizedBox(
        width: ScreenTools.screenWidth,
        height: 51.w + ScreenTools.statusBarHeight,
        child: Column(
          children: [
            Container(height: ScreenTools.statusBarHeight, color: cfff6f2fb),
            Container(
              height: 51.w,
              color: cfff6f2fb,
              child: Row(
                children: [
                  SizedBox(width: 19),
                  CButton(
                    icon: Image.asset(
                      'assets/images/canvals/edit_back_icon.png',
                      width: 26.w,
                      height: 26.w,
                    ),
                    onPressed: onBack ?? () => Get.back(),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      CButton(
                        text: "",
                        icon: Image.asset(
                          'assets/images/canvals/edit_up_icon_no.png',
                          width: 26.w,
                          height: 26.w,
                        ),
                        onPressed:
                            onUndo ??
                            () {
                              debugPrint("edit_up_icon_no-------");
                            },
                      ),
                      SizedBox(width: 19),
                      CButton(
                        text: "",
                        icon: Image.asset(
                          'assets/images/canvals/edit_next_icon_no.png',
                          width: 26.w,
                          height: 26.w,
                        ),
                        onPressed:
                            onRedo ??
                            () {
                              debugPrint("edit_next_icon_no-------");
                            },
                      ),
                      SizedBox(width: 23),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
