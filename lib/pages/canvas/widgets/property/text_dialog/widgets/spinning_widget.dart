import 'package:flutter/material.dart';

class SpinningWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool isSpinning;
  final bool clockwise;

  const SpinningWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.isSpinning = true,
    this.clockwise = true,
  });

  @override
  State<SpinningWidget> createState() => _SpinningWidgetState();
}

class _SpinningWidgetState extends State<SpinningWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _turns = _buildTurnsAnimation();

    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpinningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final durationChanged = oldWidget.duration != widget.duration;
    final directionChanged = oldWidget.clockwise != widget.clockwise;
    final spinningChanged = oldWidget.isSpinning != widget.isSpinning;

    if (durationChanged) {
      _controller.duration = widget.duration;
    }

    if (directionChanged) {
      _turns = _buildTurnsAnimation();
    }

    if (!spinningChanged && !durationChanged && !directionChanged) {
      return;
    }

    if (!widget.isSpinning) {
      _controller.stop();
      return;
    }

    // spinning=true：确保继续转；若参数变化则重启更直观
    _controller
      ..reset()
      ..repeat();
  }

  Animation<double> _buildTurnsAnimation() {
    final end = widget.clockwise ? 1.0 : -1.0;
    return Tween<double>(begin: 0.0, end: end).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _turns, child: widget.child);
  }
}
