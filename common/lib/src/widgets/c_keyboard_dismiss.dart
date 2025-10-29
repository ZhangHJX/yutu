import 'package:flutter/material.dart';

class CKeyboardDismiss extends StatelessWidget {
  const CKeyboardDismiss({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: unfocus(context), child: child);
  }
}

VoidCallback unfocus(BuildContext context) => () {
  FocusScope.of(context).unfocus();
};
