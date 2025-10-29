import 'package:flutter/material.dart';

class AnimatedSwitcherWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final void Function()? onCompleted;

  const AnimatedSwitcherWidget({
    super.key,
    required this.child,
    required this.duration,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        animation.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            onCompleted?.call();
          }
        });
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
