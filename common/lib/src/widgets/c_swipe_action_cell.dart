import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CSwipeActionCell extends StatelessWidget {
  const CSwipeActionCell({
    required this.child,
    this.isDraggable = true,
    this.onDelete,
    this.onSetDefault,
    this.onClear,
    this.onTop,
    this.isTop = false,
    super.key,
  });

  final Widget child;

  final VoidCallback? onDelete;

  final VoidCallback? onSetDefault;

  final VoidCallback? onClear;

  final VoidCallback? onTop;

  final bool isDraggable;

  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return SwipeActionCell(
      backgroundColor: Colors.transparent,
      key: ObjectKey(child),
      isDraggable: isDraggable,
      trailingActions: <SwipeAction>[
        if (onDelete != null)
          SwipeAction(
            color: Colors.transparent,
            widthSpace: 68.w,
            onTap: (handler) async {
              /// await handler(true)：表示将删除该行
              await handler(false);
              onDelete?.call();
            },
            content: Container(
              width: .infinity,
              decoration: BoxDecoration(
                color: '#FFE4554F'.color,
                borderRadius: .horizontal(right: Radius.circular(12.w)),
              ),
              child: Column(
                mainAxisAlignment: .center,
                spacing: 2.w,
                children: [
                  Image.asset('assets/images/common/ic_trash_w.png', width: 24.w, height: 24.w),
                  Text(
                    '删除',
                    style: .new(fontSize: 13.w, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        if (onSetDefault != null)
          SwipeAction(
            color: Colors.transparent,
            widthSpace: 68.w,
            style: .new(fontSize: 13.w, color: Colors.white),
            onTap: (handler) {
              handler(false);
              onSetDefault?.call();
            },
            content: Container(
              width: .infinity,
              color: '#FFFFAD2B'.color,
              child: Column(
                mainAxisAlignment: .center,
                spacing: 2.w,
                children: [
                  Image.asset('assets/images/common/ic_confirm.png', width: 24.w, height: 24.w),
                  Text(
                    '设为默认',
                    style: .new(fontSize: 13.w, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        if (onTop != null)
          SwipeAction(
            color: '#FFAE29'.color,
            widthSpace: 68.w,
            style: .new(fontSize: 14.w, color: Colors.white),
            onTap: (handler) {
              handler(false);
              onTop?.call();
            },
            title: isTop ? '取消置顶' : '置顶',
          ),
        if (onClear != null)
          SwipeAction(
            color: '#466994'.color,
            widthSpace: 100.w,
            style: .new(fontSize: 14.w, color: Colors.white),
            onTap: (handler) {
              handler(false);
              onClear?.call();
            },
            title: '清空聊天记录',
          ),
      ],
      child: child,
    );
  }
}
