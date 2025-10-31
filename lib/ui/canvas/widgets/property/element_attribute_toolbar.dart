import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../controllers/create_design_model.dart';

class ElementAttributeToolbar extends StatefulWidget {
  final EditBoxData? activeElement;
  final VoidCallback? onClose;
  final VoidCallback? onCollapse;

  const ElementAttributeToolbar({
    super.key,
    this.activeElement,
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
    if (widget.activeElement == null) {
      return SizedBox.shrink();
    }
    return Container(
      width: ScreenTools.screenWidth,
      height: 61.w,
      color: Colors.white,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: Text(
              _getToolbarTitle(),
              style: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w500,
                color: "#ff262626".color,
              ),
            ),
          ),

          Spacer(),

          GestureDetector(
            onTap: () {
              widget.onClose?.call();
            },
            child: Container(
              width: 35.w,
              height: 35.w,
              padding: EdgeInsets.all(8.w), // 添加内边距
              child: Image.asset(
                'assets/images/canvals/canvals_up_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(width: 5.w),

          GestureDetector(
            onTap: () {
              widget.onCollapse?.call();
            },
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: Container(
                width: 35.w,
                height: 35.w,
                padding: EdgeInsets.all(8.w), // 添加内边距
                child: Image.asset(
                  'assets/images/canvals/canvals_close_icon.png',
                  fit: BoxFit.cover,
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
    } else {
      return '图片属性';
    }
  }
}
