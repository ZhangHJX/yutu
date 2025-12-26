import 'package:common/src/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CAppBar extends StatelessWidget implements PreferredSizeWidget {
  CAppBar({
    super.key,
    this.title,
    this.titleText,
    this.centerTitle = true,
    this.backgroundColor,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.elevation,
    this.shadowColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    double? leadingWidth,
    this.titleSpacing = 0,
    this.toolbarHeight,
    this.leadingIconColor,
    this.bottom,
    this.titleTextStyle,
    this.flexibleSpace,
    this.shape,
    this.foregroundColor,
    this.systemOverlayStyle,
    this.appendLeading,
    this.zeroLeadingPadding = false,
    this.color = Colors.black,
    this.onBack,
  }) : assert(title == null || titleText == null, '不能同时设置title 和 titleText'),
       leadingWidth = leadingWidth ?? 45.w;

  final Widget? title;

  /// 标题文本
  final String? titleText;
  final bool centerTitle;
  final Color? backgroundColor;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final double? elevation;
  final Color? shadowColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final double toolbarOpacity;
  final double bottomOpacity;
  final double? leadingWidth;
  final double? titleSpacing;
  final double? toolbarHeight;
  final Color? leadingIconColor;
  final PreferredSizeWidget? bottom;
  final TextStyle? titleTextStyle;
  final Widget? flexibleSpace;
  final ShapeBorder? shape;
  final Color? foregroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// 拼接在返回按钮后的Widget
  final Widget? appendLeading;

  /// 返回按钮后面的间距, 默认为5.w
  final bool zeroLeadingPadding;

  final VoidCallback? onBack;

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;

    if (automaticallyImplyLeading && leading == null) {
      final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
      final bool canPop = parentRoute?.canPop ?? false;

      if (canPop) {
        leadingWidget = SizedBox.fromSize(
          size: Size(40.w, 44.w),
          child: IconButton(
            padding: .only(right: zeroLeadingPadding ? 0 : 5.w),
            icon: Image.asset(
              'assets/images/mall/ic_black_back.png',
              width: 40.w,
              height: 44.w,
              color: leadingIconColor ?? color,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();

              if (onBack != null) {
                onBack!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        );
      }
    }

    final finalTextStyle = Theme.of(
      context,
    ).appBarTheme.titleTextStyle?.merge(titleTextStyle).merge(TextStyle(color: color));

    return AppBar(
      title: title ?? (titleText != null ? Text(titleText!, style: finalTextStyle) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      leading: appendLeading == null
          ? leadingWidget
          : Row(children: [if (leadingWidget != null) leadingWidget, appendLeading!]),
      automaticallyImplyLeading: false,
      actions: actions,
      elevation: elevation,
      shadowColor: shadowColor,
      iconTheme: iconTheme,
      actionsIconTheme: actionsIconTheme,
      primary: primary,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
      leadingWidth: leadingWidth,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight,
      bottom: bottom,
      titleTextStyle: finalTextStyle,
      flexibleSpace: flexibleSpace,
      shape: shape,
      foregroundColor: foregroundColor,
      systemOverlayStyle: systemOverlayStyle,
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(
      (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0.0),
    );
  }
}
