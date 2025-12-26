import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CGestureContainer extends StatelessWidget {
  const CGestureContainer({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.child,
    this.clipBehavior = .none,
    this.onTap,
    this.useAnimated = false,
    this.behavior = .opaque,
  });

  final VoidCallback? onTap;
  final Widget? child;
  final Alignment? alignment;
  final EdgeInsets? padding;
  final Color? color;
  final BoxDecoration? decoration;
  final BoxDecoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsets? margin;
  final Alignment? transformAlignment;
  final Clip clipBehavior;
  final Matrix4? transform;
  final bool useAnimated;
  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) {
    final container = useAnimated
        ? AnimatedContainer(
            alignment: alignment,
            padding: padding,
            decoration: decoration ?? BoxDecoration(color: color),
            foregroundDecoration: foregroundDecoration,
            width: width,
            height: height,
            constraints: constraints,
            margin: margin,
            transform: transform,
            transformAlignment: transformAlignment,
            duration: 250.ms,
            child: child,
          )
        : Container(
            alignment: alignment,
            padding: padding,
            decoration: decoration ?? BoxDecoration(color: color),
            foregroundDecoration: foregroundDecoration,
            width: width,
            height: height,
            constraints: constraints,
            margin: margin,
            transform: transform,
            transformAlignment: transformAlignment,
            clipBehavior: clipBehavior,
            child: child,
          );
    return onTap == null
        ? container
        : GestureDetector(onTap: onTap, behavior: behavior, child: container);
  }
}

class CContainer extends CGestureContainer {
  const CContainer({
    super.key,
    super.alignment,
    super.padding,
    super.color,
    super.decoration,
    super.foregroundDecoration,
    super.width,
    super.height,
    super.constraints,
    super.margin,
    super.transform,
    super.transformAlignment,
    super.child,
    super.clipBehavior = .none,
    super.onTap,
    super.useAnimated = false,
    super.behavior = .opaque,
  });

  @override
  Widget build(BuildContext context) {
    final finalDecoration =
        decoration ??
        BoxDecoration(color: Colors.white, borderRadius: .circular(12.w)).copyWith(color: color);
    return CGestureContainer(
      alignment: alignment,
      padding: padding,
      decoration: finalDecoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      onTap: onTap,
      useAnimated: useAnimated,
      child: child,
    );
  }
}
