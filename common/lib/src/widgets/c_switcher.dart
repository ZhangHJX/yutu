import 'package:flutter/material.dart';

class CScaleSwitcher extends StatelessWidget {
  const CScaleSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (widget, anim) => ScaleTransition(scale: anim, child: widget),
      child: child,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(children: [...previousChildren, if (currentChild != null) currentChild]);
      },
    );
  }
}

class CFadeSwitcher extends StatefulWidget {
  const CFadeSwitcher({required this.child, super.key});

  final Widget child;

  @override
  State<CFadeSwitcher> createState() => _CFadeSwitcherState();
}

class _CFadeSwitcherState extends State<CFadeSwitcher> {
  Widget? _prevChild;

  @override
  Widget build(BuildContext context) {
    final first = _prevChild == null;
    _prevChild = widget.child;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return first ? child : FadeTransition(opacity: animation, child: child);
      },
      child: widget.child,
    );
  }
}
