import 'dart:async';
import 'package:flutter/material.dart';

/// 简单帧动画：frames = 多张png帧（assets路径列表）
/// playing=true -> 开始循环播放
/// playing=false -> 停止（可选重置到第0帧）
class FrameAnimatedAsset extends StatefulWidget {
  final List<String> frames;
  final bool playing;
  final double width;
  final double height;

  /// 每帧间隔
  final Duration frameDuration;

  /// 停止时是否回到第0帧
  final bool resetOnStop;

  /// 是否循环
  final bool loop;

  const FrameAnimatedAsset({
    super.key,
    required this.frames,
    required this.playing,
    required this.width,
    required this.height,
    this.frameDuration = const Duration(milliseconds: 60),
    this.resetOnStop = true,
    this.loop = true,
  });

  @override
  State<FrameAnimatedAsset> createState() => _FrameAnimatedAssetState();
}

class _FrameAnimatedAssetState extends State<FrameAnimatedAsset> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 预缓存，避免播放时抖动（可选但很推荐）
    for (final p in widget.frames) {
      precacheImage(AssetImage(p), context);
    }
  }

  @override
  void initState() {
    super.initState();
    _syncPlaying();
  }

  @override
  void didUpdateWidget(covariant FrameAnimatedAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中状态变化时，开始/停止
    if (oldWidget.playing != widget.playing ||
        oldWidget.frames != widget.frames ||
        oldWidget.frameDuration != widget.frameDuration ||
        oldWidget.loop != widget.loop) {
      _syncPlaying();
    }
  }

  void _syncPlaying() {
    _timer?.cancel();
    _timer = null;

    if (!widget.playing || widget.frames.isEmpty) {
      if (widget.resetOnStop) {
        _index = 0;
      }
      if (mounted) setState(() {});
      return;
    }

    _timer = Timer.periodic(widget.frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_index >= widget.frames.length - 1) {
          _index = widget.loop ? 0 : widget.frames.length - 1;
          if (!widget.loop) {
            _timer?.cancel();
            _timer = null;
          }
        } else {
          _index++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    final path = widget.frames[_index.clamp(0, widget.frames.length - 1)];
    return Image.asset(path, width: widget.width, height: widget.height);
  }
}
