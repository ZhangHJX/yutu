import 'package:flutter/material.dart';

class DiagonalGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const DiagonalGradientText({
    super.key,
    required this.text,
    required this.style,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}
