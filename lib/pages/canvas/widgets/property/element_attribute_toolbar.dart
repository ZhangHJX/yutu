import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/index.dart';

class ElementAttributeToolbar extends StatefulWidget {
  final CanvasElement? activeElement;
  final VoidCallback? onClose;
  final Function(String)? onCollapse;
  final bool isCanvasSelected; // 是否选中画布

  const ElementAttributeToolbar({
    super.key,
    this.activeElement,
    this.isCanvasSelected = false,
    this.onClose,
    this.onCollapse,
  });

  @override
  State<ElementAttributeToolbar> createState() =>
      _ElementAttributeToolbarState();
}

class _ElementAttributeToolbarState extends State<ElementAttributeToolbar> {
  @override
  Widget build(BuildContext context) {
    if (widget.activeElement == null && !widget.isCanvasSelected) {
      return SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 20.w),
      height: 61.w,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.onCollapse?.call(_getToolbarTitle());
              },
              child: Row(
                children: [
                  Text(
                    _getToolbarTitle(),
                    style: TextStyle(
                      fontSize: 16.w,
                      fontWeight: FontWeight.w500,
                      color: "#ff262626".color,
                    ),
                  ),

                  Spacer(),

                  SizedBox(
                    width: 35.w,
                    height: 35.w,
                    child: Center(
                      child: Image.asset(
                        'assets/images/canvals/canvals_up_icon.png',
                        fit: BoxFit.fill,
                        width: 14.w,
                        height: 14.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onClose?.call();
            },
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: SizedBox(
                width: 35.w,
                height: 35.w,
                child: Center(
                  child: Image.asset(
                    'assets/images/canvals/canvals_close_icon.png',
                    fit: BoxFit.fill,
                    width: 14.w,
                    height: 14.w,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据元素类型获取工具栏标题
  String _getToolbarTitle() {
    final elementType = widget.activeElement?.type;
    if (elementType == ElementType.rectangle ||
        elementType == ElementType.ellipse ||
        elementType == ElementType.line) {
      return '形状属性';
    } else if (elementType == ElementType.text) {
      return '文字属性';
    } else if (elementType == ElementType.image) {
      return '图片属性';
    } else {
      return '画布属性';
    }
  }
}
