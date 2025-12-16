import 'package:flutter/material.dart';

class SelectItemGradientBorder extends StatelessWidget {
  final bool isSelected;
  final Widget child;

  final double radius;
  final double borderWidth;

  final Gradient selectedGradient;
  final Color backgroundColor;

  final Color unselectedBorderColor;
  final double unselectedBorderWidth;

  final EdgeInsetsGeometry padding;

  const SelectItemGradientBorder({
    super.key,
    required this.isSelected,
    required this.child,
    this.radius = 8,
    this.borderWidth = 2,
    this.selectedGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9B7BFF), Color(0xFF5B8CFF)],
    ),
    this.backgroundColor = Colors.white,
    this.unselectedBorderColor = const Color(0xFFE6E6E6),
    this.unselectedBorderWidth = 1,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final double innerRadius = (radius - borderWidth).clamp(0, radius);

    if (!isSelected) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: unselectedBorderColor,
            width: unselectedBorderWidth,
          ),
        ),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: selectedGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(innerRadius),
        ),
        child: child,
      ),
    );
  }
}
