import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 画布缩放控制浮框
class CanvasControlWidget extends StatelessWidget {
  final double scale; // 当前缩放比例
  final VoidCallback onFitScreen; // 适应屏幕回调
  final VoidCallback? onZoomIn; // 放大回调
  final VoidCallback? onZoomOut; // 缩小回调

  const CanvasControlWidget({
    super.key,
    required this.scale,
    required this.onFitScreen,
    this.onZoomIn,
    this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    // 将缩放比例转换为百分比
    final scalePercent = (scale * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "适应屏幕"按钮
        GestureDetector(
          onTap: onFitScreen,
          behavior: HitTestBehavior.opaque, // 只响应按钮区域的手势
          child: Image.asset(
            'assets/images/canvals/canvals_floating_icon.png',
            width: 69.w,
            height: 28.25.w,
            fit: BoxFit.fill,
          ),
        ),

        // 缩放比例显示（加号和减号可点击）
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.w),
            border: Border.all(color: "#E6E6E6".color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 加号按钮
              GestureDetector(
                onTap: onZoomIn,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 10.w,
                  ),
                  child: Image.asset(
                    'assets/images/canvals/canvals_floating_add.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              SizedBox(width: 5.w),

              // 缩放比例显示（不可点击）
              IgnorePointer(
                child: Text(
                  '$scalePercent%',
                  style: TextStyle(
                    color: "#232535".color,
                    fontSize: 13.w,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(width: 5.w),

              // 减号按钮
              GestureDetector(
                onTap: onZoomOut,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 10.w,
                  ),
                  child: Image.asset(
                    'assets/images/canvals/canvals_floating_minxs.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
