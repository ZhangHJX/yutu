import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef OnWidgetSizeChange = void Function(Size size, Offset offset);

class CMeasureSize extends StatefulWidget {
  const CMeasureSize({required this.onChange, required this.child, super.key});

  final Widget child;
  final OnWidgetSizeChange onChange;

  @override
  State<CMeasureSize> createState() => _CMeasureSizeState();
}

class _CMeasureSizeState extends State<CMeasureSize> with SingleTickerProviderStateMixin {
  Size? _oldSize;
  Offset? _oldOffset;
  bool _hasScheduledCallback = false;

  @override
  void initState() {
    super.initState();
    _schedulePostFrameCallback();
  }

  @override
  void didUpdateWidget(CMeasureSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _schedulePostFrameCallback();
    }
  }

  void _schedulePostFrameCallback() {
    if (!_hasScheduledCallback) {
      _hasScheduledCallback = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _hasScheduledCallback = false;
        _measureSize();
      });
    }
  }

  void _measureSize() {
    if (!mounted) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // 只有当尺寸或位置发生变化时才触发回调
    if (_oldSize != size || _oldOffset != offset) {
      _oldSize = size;
      _oldOffset = offset;
      widget.onChange(size, offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 在每次build时调度测量，确保捕获所有布局变化
    _schedulePostFrameCallback();

    return widget.child;
  }

  @override
  void dispose() {
    _hasScheduledCallback = false;
    super.dispose();
  }
}
