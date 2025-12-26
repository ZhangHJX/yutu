import 'package:common/common.dart';
import 'package:flutter/material.dart';

class PageNavigationBar extends StatelessWidget {
  const PageNavigationBar({
    super.key,
    this.child,
    this.height,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget? child;
  final double? height; // 不传就用默认 146.w
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ["#9ADEFD".color, "#FFFFFF".color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
