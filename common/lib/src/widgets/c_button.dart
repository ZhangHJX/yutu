import 'package:flutter/material.dart';

import 'c_gradient_border_painter.dart';
import 'c_gradient_text.dart';

enum CIconPosition { left, right, top, bottom }

class CButton extends StatelessWidget {
  const CButton({
    super.key,
    this.text,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.iconPosition = CIconPosition.left,
    this.spacing = 0,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.border,
    this.borderWidth,
    this.borderColor,
    this.borderRadius = 0,
    this.boxShadow,
    this.shadowColor,
    this.shadowOffset,
    this.shadowBlurRadius,
    this.onPressed,
    this.width,
    this.height,
    this.gradient,
    this.useDefaultGradient = false,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.disabled = false,
    this.disabledOpacity = 0.6,
    this.ghost = false,
    this.textStyle,
    this.lineHeight,
    this.decoration,
    this.iconOffset,
    this.behavior = HitTestBehavior.opaque,
  }) : assert(text != null || icon != null, '文本和图标至少需要设置一个');

  factory CButton.icon({
    required Widget child,
    Key? key,
    double? size,
    Color? color,
    VoidCallback? onPressed,
    Color? backgroundColor,
    double? borderRadius,
    bool disabled = false,
    BuildContext? context,
    EdgeInsetsGeometry? padding,
    Gradient? gradient,
    bool? useDefaultGradient,
    bool ghost = false,
  }) {
    final Color primaryColor = context != null ? Theme.of(context).primaryColor : Colors.blue;

    return CButton(
      key: key,
      icon: child,
      iconSize: size,
      iconColor: color ?? primaryColor,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius ?? 4.0,
      onPressed: onPressed,
      disabled: disabled,
      padding: padding ?? EdgeInsets.zero,
      gradient: gradient,
      useDefaultGradient: useDefaultGradient,
      ghost: ghost,
    );
  }

  factory CButton.text({
    required String text,
    Key? key,
    Widget? icon,
    CIconPosition iconPosition = CIconPosition.left,
    double spacing = 8.0,
    VoidCallback? onPressed,
    Color? textColor,
    double? fontSize,
    bool disabled = false,
    EdgeInsetsGeometry? padding,
    Gradient? gradient,
    bool? useDefaultGradient,
    bool ghost = false,
  }) {
    // final Color primaryColor = context != null ? Theme.of(context).primaryColor : Colors.blue;

    return CButton(
      key: key,
      text: text,
      icon: icon,
      iconPosition: iconPosition,
      spacing: spacing,
      backgroundColor: Colors.transparent,
      // textColor: textColor ?? primaryColor,
      textColor: textColor,
      fontSize: fontSize,
      onPressed: onPressed,
      disabled: disabled,
      padding: padding ?? EdgeInsets.zero,
      gradient: gradient,
      useDefaultGradient: useDefaultGradient,
      ghost: ghost,
    );
  }

  final dynamic text;

  final TextStyle? textStyle;

  final double? lineHeight;

  final Offset? iconOffset;

  final Widget? icon;

  final double? iconSize;

  final Color? iconColor;

  final HitTestBehavior? behavior;

  final MainAxisSize mainAxisSize;

  final CIconPosition iconPosition;

  final double spacing;

  final MainAxisAlignment mainAxisAlignment;

  final CrossAxisAlignment crossAxisAlignment;

  final Color? backgroundColor;

  final Color? textColor;

  final double? fontSize;

  final Border? border;

  final double? borderWidth;

  final Color? borderColor;

  final double borderRadius;

  final List<BoxShadow>? boxShadow;

  final Color? shadowColor;

  final Offset? shadowOffset;

  final double? shadowBlurRadius;

  final VoidCallback? onPressed;

  final double? width;

  final double? height;

  final EdgeInsetsGeometry padding;

  final EdgeInsetsGeometry margin;

  final Gradient? gradient;

  final bool? useDefaultGradient;

  final bool disabled;

  final double disabledOpacity;

  final bool ghost;

  /// 优先级最高
  /// 如果设置了该属性，则不会使用其他的属性, 如borderRadius, borderColor, gradient等
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final Gradient effectiveGradient =
        gradient ??
        ((useDefaultGradient ?? false)
            ? LinearGradient(
                colors: [Color(0xFFFFAD2B), Color(0xFFFAC209)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : defaultGradient);

    // 文本组件
    // final TextStyle defaultTextStyle = textStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final TextStyle defaultTextStyle = textStyle ?? const TextStyle();
    final TextStyle finalTextStyle = defaultTextStyle.copyWith(
      color: textColor,
      fontSize: fontSize,
      height: lineHeight,
    );

    final Widget? textWidget = text is String
        ? ghost
              ? CGradientText(text, style: finalTextStyle, gradient: effectiveGradient)
              : Text(text, style: finalTextStyle, textAlign: TextAlign.center)
        : text is Widget
        ? text
        : null;

    // 图标组件
    final Color effectiveIconColor = ghost
        ? textColor ?? Theme.of(context).primaryColor
        : iconColor ?? textColor ?? Theme.of(context).primaryColor;

    final Widget? iconWidget = icon == null
        ? null
        : IconTheme(
            data: IconThemeData(size: iconSize, color: effectiveIconColor),
            child: iconOffset == null
                ? icon!
                : Transform.translate(offset: iconOffset!, child: icon),
          );

    Widget content;
    if (textWidget == null) {
      content = Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [iconWidget!],
      );
    } else if (iconWidget == null) {
      content = Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [textWidget],
      );
    } else {
      final bool isIconFirst =
          iconPosition == CIconPosition.left || iconPosition == CIconPosition.top;
      final bool isHorizontal =
          iconPosition == CIconPosition.left || iconPosition == CIconPosition.right;
      final firstWidget = isIconFirst ? iconWidget : textWidget;
      final secondWidget = isIconFirst ? textWidget : iconWidget;

      content = Flex(
        direction: isHorizontal ? Axis.horizontal : Axis.vertical,
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          firstWidget,
          SizedBox(width: isHorizontal ? spacing : 0, height: isHorizontal ? 0 : spacing),
          secondWidget,
        ],
      );
    }

    Widget buttonChild;

    if (ghost) {
      buttonChild = Container(
        width: width,
        height: height,
        padding: padding,
        decoration:
            decoration ??
            BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
        child: CustomPaint(
          painter: CGradientBorderPainter(gradient: effectiveGradient, borderRadius: borderRadius),
          child: Container(padding: padding, alignment: Alignment.center, child: content),
        ),
      );
    } else {
      buttonChild = Container(
        width: width,
        height: height,
        padding: padding,
        decoration: decoration?.copyWith(gradient: gradient) ?? fallbackDecoration(shadows()),
        child: content,
      );
    }

    if (disabled) {
      return Padding(
        padding: margin,
        child: Opacity(opacity: disabledOpacity, child: buttonChild),
      );
    }

    return Padding(
      padding: margin,
      child: onPressed == null
          ? buttonChild
          : GestureDetector(behavior: behavior, onTap: onPressed, child: buttonChild),
    );
  }

  List<BoxShadow> shadows() {
    final List<BoxShadow> shadows =
        boxShadow ??
        (shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor!,
                  offset: shadowOffset ?? Offset.zero,
                  blurRadius: shadowBlurRadius ?? 3.0,
                ),
              ]
            : []);
    return shadows;
  }

  BoxDecoration fallbackDecoration(List<BoxShadow> shadows) {
    final BoxDecoration fallbackDecoration = BoxDecoration(
      color: backgroundColor,
      gradient:
          gradient ??
          ((useDefaultGradient ?? false)
              ? LinearGradient(
                  colors: [Color(0xFFFFAD2B), Color(0xFFFAC209)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null),
      borderRadius: BorderRadius.circular(borderRadius),
      border:
          border ??
          (borderColor != null ? Border.all(color: borderColor!, width: borderWidth ?? 1.0) : null),
      boxShadow: shadows,
    );
    return fallbackDecoration;
  }
}
