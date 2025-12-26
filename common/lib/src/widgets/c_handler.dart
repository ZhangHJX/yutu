import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CHandler extends StatelessWidget {
  const CHandler(this.builder, {super.key});

  final WidgetCreator builder;

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}
