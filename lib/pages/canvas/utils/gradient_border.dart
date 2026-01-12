import 'package:flutter/material.dart';

class GradientBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final List<Color> gradientColors;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  const GradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    required this.gradientColors,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            borderRadius.topLeft.x - borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
