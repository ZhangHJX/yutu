import 'package:flutter/material.dart';

class CGradientText extends StatelessWidget {
  const CGradientText(
    this.text, {
    this.gradient = defaultGradient,
    super.key,
    this.style,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final textChild = Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      textAlign: textAlign,
    );
    return ShaderMask(
      shaderCallback: gradient.createShader,
      child: Container(
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        child: textChild,
      ),
    );
  }
}

class CGradientWidget extends StatelessWidget {
  const CGradientWidget(this.child, {this.gradient = defaultGradient, super.key});

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(shaderCallback: gradient.createShader, child: child);
  }
}

const defaultGradientColors = [Color(0xFFFFAD2B), Color(0xFFFAC209)];

const LinearGradient defaultGradient = LinearGradient(
  colors: defaultGradientColors,
  begin: Alignment(-0.3, -1),
  end: Alignment(1, 0.3),
);

LinearGradient getGradient(
  List<Color> colors, {
  Alignment begin = const Alignment(-0.3, -1),
  Alignment end = const Alignment(1, 0.3),
  List<double> stops = const [0, 1],
}) {
  return LinearGradient(colors: colors, begin: begin, end: end, stops: stops);
}
