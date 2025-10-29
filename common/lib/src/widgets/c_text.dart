import 'package:flutter/material.dart';

class CText extends StatelessWidget {
  const CText(
    this.text, {
    this.offset,
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.margin,
    this.decoration,
  });

  final Offset? offset;
  final String? text;
  final int? maxLines;
  final TextStyle? style;
  final EdgeInsets? margin;
  final TextAlign textAlign;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    TextStyle? style = this.style;

    if (style == null) {
      final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
      style = defaultTextStyle.style;
    }

    if (maxLines != null) {
      style = style.copyWith(overflow: TextOverflow.ellipsis);
    }

    Widget child = Text(
      text ?? '',
      style: style.copyWith(decoration: decoration),
      textAlign: textAlign,
      maxLines: maxLines,
    );

    if (offset != null) {
      child = Transform.translate(offset: offset!, child: child);
    }

    if (margin != null) {
      child = Padding(padding: margin!, child: child);
    }

    return child;
  }
}
