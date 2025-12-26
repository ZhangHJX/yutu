import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 权限说明浮层 Widget
class PermissionOverlayWidget extends StatelessWidget {
  final String title;
  final String message;

  const PermissionOverlayWidget({
    required this.title,
    required this.message,
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // 不拦截触摸事件，让系统权限对话框可以正常交互
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            width: ScreenTools.screenWidth - 24.w,
            constraints: const BoxConstraints(maxHeight: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.w,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.w,
                    height: 1.5,
                    color: "#232535".color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
