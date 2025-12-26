import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CTag extends StatelessWidget {
  const CTag(
    this.text, {
    this.color,
    this.borderColor,
    this.borderRadius,
    super.key,
    this.padding,
    this.margin,
    this.fontSize,
    this.lineHeight,
    this.backgroundColor,
    this.constraints,
    this.height,
    this.width,
  });

  final String text;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final double? fontSize;
  final double? width;
  final double? height;
  final double? lineHeight;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: .center,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      constraints: constraints,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor != null || color != null
            ? Border.all(color: borderColor ?? color!, width: hairline)
            : null,
        borderRadius: borderRadius,
      ),
      child: Text(
        text,
        style: .new(color: color, fontSize: fontSize, height: lineHeight),
      ),
    );
  }
}
