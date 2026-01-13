import 'package:flutter/material.dart';

class FrameSequenceAnim extends StatefulWidget {
  const FrameSequenceAnim({
    super.key,
    required this.frames,
    this.fps = 24,
    this.loop = true,
    this.width,
    this.height,
  });

  final List<String> frames; // asset 路径列表
  final int fps;
  final bool loop;
  final double? width;
  final double? height;

  @override
  State<FrameSequenceAnim> createState() => _FrameSequenceAnimState();
}

class _FrameSequenceAnimState extends State<FrameSequenceAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    final duration = Duration(
      milliseconds: (widget.frames.length * 1000 ~/ widget.fps),
    );
    _ctl = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((s) {
        if (!widget.loop && s == AnimationStatus.completed) _ctl.stop();
      });
    widget.loop ? _ctl.repeat() : _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final idx = ((widget.frames.length * _ctl.value).floor()).clamp(
          0,
          widget.frames.length - 1,
        );
        return Image.asset(
          widget.frames[idx],
          gaplessPlayback: true, // 切换时减少闪烁
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        );
      },
    );
  }
}
