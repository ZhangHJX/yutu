import 'package:common/common.dart';
import 'package:flutter/material.dart';

class MiddleLoadingWidget extends StatelessWidget {
  final String title;
  final String cancelTitle;
  final VoidCallback? cancelAction;

  const MiddleLoadingWidget({
    super.key,
    this.title = "加载中",
    this.cancelAction,
    this.cancelTitle = "取消",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277.w,
      padding: EdgeInsets.only(top: 24.w, bottom: 36.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 加载中文本
          Text(
            title,
            style: TextStyle(
              fontSize: 18.w,
              color: "#232535".color,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 25.w),

          // 加载动画
          SizedBox(width: 66.w, height: 66.w, child: _LoadingSpinner()),

          SizedBox(height: 35.w),

          // 取消按钮
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: GestureDetector(
              onTap: () {
                cancelAction?.call();
                SmartDialog.dismiss();
              },
              child: Container(
                width: double.infinity,
                height: 40.w,
                decoration: BoxDecoration(
                  color: "#E8E8E8".color,
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Center(
                  child: Text(
                    cancelTitle,
                    style: TextStyle(
                      fontSize: 16.w,
                      color: "#222325".color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载动画 - 使用图片资源并旋转
class _LoadingSpinner extends StatefulWidget {
  const _LoadingSpinner();

  @override
  State<_LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<_LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      child: Image.asset(
        'assets/images/home/middle_loading_icon.png',
        width: 66.w,
        height: 66.w,
        fit: BoxFit.contain,
      ),
    );
  }
}
