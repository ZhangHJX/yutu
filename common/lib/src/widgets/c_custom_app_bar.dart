import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CCustomAppBar extends HookWidget implements PreferredSizeWidget {
  const CCustomAppBar({
    super.key,
    this.bottom,
    this.backgroundColor,
    this.title,
    this.titleTextStyle,
    this.leading,
  });

  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Widget? title;
  final TextStyle? titleTextStyle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final leftWidth = useState<double>(0);

    final AppBarThemeData appBarTheme = AppBarTheme.of(context);
    final finalTitleTextStyle =
        titleTextStyle ?? appBarTheme.titleTextStyle ?? Theme.of(context).textTheme.titleLarge;

    Widget content = Row(
      children: [
        Row(
          children: [
            CMeasureSize(
              child: CButton(
                icon: Image.asset(
                  'assets/images/mall/ic_black_back.png',
                  width: 40.w,
                  height: 56.w,
                ),
                onPressed: Get.back,
              ),
              onChange: (size, _) => leftWidth.value = size.width,
            ),
            if (leading != null) leading!,
          ],
        ),
        if (title != null)
          Expanded(
            child: Container(
              alignment: .center,
              margin: .symmetric(horizontal: 8),
              child: DefaultTextStyle(style: finalTitleTextStyle!, child: title!),
            ),
          ),
        SizedBox(width: leftWidth.value),
      ],
    );

    if (bottom != null) {
      content = Column(children: [content, bottom!]);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        // border: Border(bottom: borderSide),
        // boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4.w, offset: Offset(0, -4.w))],
      ),
      child: SafeArea(child: content),
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
  }
}
