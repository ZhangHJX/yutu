import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 画布顶部应用栏
class CanvasAppBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;

  const CanvasAppBar(
    this.onBack,
    this.onUndo,
    this.onRedo, {
    super.key,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ScreenTools.screenWidth,
      height: 51.w + ScreenTools.statusBarHeight,
      child: Column(
        children: [
          Container(
            height: ScreenTools.statusBarHeight,
            color: Color(0xfff6f2fb),
          ),
          Container(
            height: 51.w,
            color: Color(0xfff6f2fb),
            child: Row(
              children: [
                SizedBox(width: 19),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    onBack.call();
                  },
                  child: SizedBox(
                    width: 30.w,
                    height: 30.w,
                    child: Image.asset(
                      'assets/images/canvals/edit_back_icon.png',
                      width: 26.w,
                      height: 26.w,
                    ),
                  ),
                ),

                Spacer(),

                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (canUndo) {
                          onUndo.call();
                        }
                      },
                      child: SizedBox(
                        width: 30.w,
                        height: 30.w,
                        child: Image.asset(
                          canUndo
                              ? 'assets/images/canvals/edit_up_icon_have.png'
                              : 'assets/images/canvals/edit_up_icon_no.png',
                          width: 26.w,
                          height: 26.w,
                        ),
                      ),
                    ),

                    SizedBox(width: 19),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (canRedo) {
                          onRedo.call();
                        }
                      },
                      child: SizedBox(
                        width: 30.w,
                        height: 30.w,
                        child: Image.asset(
                          canRedo
                              ? 'assets/images/canvals/edit_next_icon_have.png'
                              : 'assets/images/canvals/edit_next_icon_no.png',
                          width: 26.w,
                          height: 26.w,
                        ),
                      ),
                    ),

                    SizedBox(width: 23),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
