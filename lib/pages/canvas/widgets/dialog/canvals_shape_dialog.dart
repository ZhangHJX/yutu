import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/index.dart';

enum ShapeType { rectangle, ellipse, line }

class CanvalsShapeDialog extends StatefulWidget {
  final Function(ElementType) onShapeSelected;
  const CanvalsShapeDialog({super.key, required this.onShapeSelected});
  @override
  State<CanvalsShapeDialog> createState() => _CanvalsShapeDialogState();
}

class _CanvalsShapeDialogState extends State<CanvalsShapeDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 237.w + ScreenTools.bottomBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.w),
          topRight: Radius.circular(18.w),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.only(top: 19.w),
            height: 49.w,
            width: ScreenTools.screenWidth,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '框',
                    style: TextStyle(
                      fontSize: 18.w,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff262626),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      SmartDialog.dismiss();
                    },
                    child: SizedBox(
                      width: 45.w,
                      height: 30.w,
                      child: Center(
                        child: Image.asset(
                          'assets/images/canvals/canvals_close_icon.png',
                          width: 12.w,
                          height: 12.w,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 形状选择区域
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShapeButton(label: '矩形', type: ElementType.rectangle),
                _buildShapeButton(label: '椭圆', type: ElementType.ellipse),
                _buildShapeButton(label: '线条', type: ElementType.line),
              ],
            ),
          ),

          // 底部安全区域
          SizedBox(height: ScreenTools.bottomBarHeight),
        ],
      ),
    );
  }

  Widget _buildShapeButton({required String label, required ElementType type}) {
    return GestureDetector(
      onTap: () {
        widget.onShapeSelected(type);
        SmartDialog.dismiss();
      },
      child: Container(
        width: 92.w,
        height: 92.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: Color(0xFFE6E6E6), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (type == ElementType.rectangle)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: '#FF2E2E2E'.color, width: 2.w),
                  borderRadius: BorderRadius.circular(6.w),
                ),
                height: 33.w,
                width: 33.w,
              ),

            if (type == ElementType.ellipse)
              Padding(
                padding: EdgeInsets.only(bottom: 6.w),
                child: Container(
                  width: 40.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: Colors.white, // 填充色
                    border: Border.all(
                      color: '#FF2E2E2E'.color, // 边框颜色
                      width: 2.w, // 边框宽度
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(20.w, 10.w),
                    ),
                  ),
                ),
              ),

            if (type == ElementType.line)
              Padding(
                padding: EdgeInsets.only(bottom: 15.w),
                child: Container(
                  color: '#FF2E2E2E'.color,
                  height: 2.w,
                  width: 40.w,
                ),
              ),

            Padding(
              padding: EdgeInsets.only(top: 5.w, bottom: 9.w),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.w,
                  color: Color(0xFF2E2E2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
