import 'package:flutter/material.dart';

/// 自动滚动的 TabBar Widget
/// 支持点击 item 后自动滚动到可视区域或居中
class AutoScrollTabBar extends StatefulWidget {
  /// Tab items 列表
  final List<Widget> children;

  /// 滚动方向，默认为横向
  final Axis scrollDirection;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 是否在点击时滚动到居中位置，默认为 true
  /// 如果为 false，则滚动到可视区域边缘
  final bool scrollToCenter;

  /// 滚动动画时长
  final Duration scrollDuration;

  /// 滚动动画曲线
  final Curve scrollCurve;

  /// 右侧预留空间（用于放置其他组件，如右侧固定按钮）
  final double? rightPadding;

  const AutoScrollTabBar({
    super.key,
    required this.children,
    this.scrollDirection = Axis.horizontal,
    this.padding,
    this.scrollToCenter = true,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.scrollCurve = Curves.easeInOut,
    this.rightPadding,
  });

  @override
  State<AutoScrollTabBar> createState() => AutoScrollTabBarState();
}

class AutoScrollTabBarState extends State<AutoScrollTabBar> {
  final GlobalKey _scrollViewKey = GlobalKey();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    // 为每个 child 创建 GlobalKey
    for (int i = 0; i < widget.children.length; i++) {
      _itemKeys[i] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(AutoScrollTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 children 数量发生变化，更新 keys
    if (widget.children.length != oldWidget.children.length) {
      // 保留现有的 keys，只添加新的
      final oldLength = oldWidget.children.length;
      final newLength = widget.children.length;

      if (newLength > oldLength) {
        // 添加新的 keys
        for (int i = oldLength; i < newLength; i++) {
          _itemKeys[i] = GlobalKey();
        }
      } else if (newLength < oldLength) {
        // 移除多余的 keys
        _itemKeys.removeWhere((key, value) => key >= newLength);
      }
    }
  }

  /// 滚动到指定索引的 item
  void scrollToItem(int index) {
    if (index < 0 || index >= widget.children.length) return;
    if (!_itemKeys.containsKey(index)) return;

    final key = _itemKeys[index];
    if (key == null) return;
    final itemContext = key.currentContext;
    if (itemContext == null) return;

    // 等待一帧，确保布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 再次检查 context 是否仍然有效
      final context = key.currentContext;
      if (context == null) return;

      // 使用 Scrollable.ensureVisible 来滚动到指定位置
      Scrollable.ensureVisible(
        context,
        duration: widget.scrollDuration,
        curve: widget.scrollCurve,
        alignment: widget.scrollToCenter ? 0.5 : 0.0,
        alignmentPolicy: widget.scrollToCenter
            ? ScrollPositionAlignmentPolicy.explicit
            : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: _scrollViewKey,
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.children.length, (index) {
          final child = widget.children[index];
          final key = _itemKeys[index]!;

          // 使用 KeyedSubtree 包装，确保 key 正确传递
          return KeyedSubtree(key: key, child: child);
        }),
      ),
    );
  }
}
