import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 分割线类型
enum CDividerType {
  /// 水平分割线
  horizontal,

  /// 垂直分割线
  vertical,
}

/// 标题位置
enum CDividerTitlePlacement {
  /// 左侧/顶部
  left,

  /// 居中
  center,

  /// 右侧/底部
  right,
}

/// 自定义分割线组件
class CDivider extends StatelessWidget {
  CDivider({
    super.key,
    this.color,
    this.type = CDividerType.horizontal,
    double? thickness,
    this.length,
    this.dashed = false,
    this.dashGap = 3.0,
    this.dashWidth = 5.0,
    this.title,
    this.titleColor,
    this.titlePlacement = CDividerTitlePlacement.center,
    this.titleOffset = 0.0,
    this.titleStyle,
    this.titleSpacing = 8.0,
    this.padding = EdgeInsets.zero,
    this.gradient,
    this.borderRadius,
  }) : thickness = thickness ?? hairline;

  /// 创建水平分割线
  factory CDivider.horizontal({
    Key? key,
    Color? color,
    double thickness = 1.0,
    double? width,
    bool dashed = false,
    double dashGap = 3.0,
    double dashWidth = 5.0,
    dynamic title,
    CDividerTitlePlacement titlePlacement = CDividerTitlePlacement.center,
    double titleOffset = 0.0,
    TextStyle? titleStyle,
    double titleSpacing = 8.0,
    Color? titleColor,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BorderRadius? borderRadius,
  }) {
    return CDivider(
      key: key,
      color: color,
      thickness: thickness,
      length: width,
      dashed: dashed,
      dashGap: dashGap,
      dashWidth: dashWidth,
      title: title,
      titlePlacement: titlePlacement,
      titleOffset: titleOffset,
      titleStyle: titleStyle,
      titleSpacing: titleSpacing,
      padding: padding,
      titleColor: titleColor,
      borderRadius: borderRadius,
    );
  }

  /// 创建垂直分割线
  factory CDivider.vertical({
    Key? key,
    Color? color,
    double thickness = 1.0,
    double? height,
    bool dashed = false,
    double dashGap = 3.0,
    double dashWidth = 5.0,
    dynamic title,
    CDividerTitlePlacement titlePlacement = CDividerTitlePlacement.center,
    double titleOffset = 0.0,
    TextStyle? titleStyle,
    double titleSpacing = 8.0,
    Color? titleColor,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Gradient? gradient,
    BorderRadius? borderRadius,
  }) {
    return CDivider(
      key: key,
      color: color,
      type: CDividerType.vertical,
      thickness: thickness,
      length: height,
      dashed: dashed,
      dashGap: dashGap,
      dashWidth: dashWidth,
      titleColor: titleColor,
      title: title,
      titlePlacement: titlePlacement,
      titleOffset: titleOffset,
      titleStyle: titleStyle,
      titleSpacing: titleSpacing,
      padding: padding,
      gradient: gradient,
      borderRadius: borderRadius,
    );
  }

  /// 圆角
  final BorderRadius? borderRadius;

  /// 分割线渐变
  final Gradient? gradient;

  /// 分割线颜色
  final Color? color;

  /// 分割线类型
  final CDividerType type;

  /// 粗细
  /// 当type为horizontal时, 粗细为height
  /// 当type为vertical时, 粗细为width
  final double thickness;

  /// 长度
  /// 当type为horizontal时, 长度为width
  /// 当type为vertical时, 长度为height
  final double? length;

  /// 是否为虚线
  final bool dashed;

  /// 虚线的间隔
  final double dashGap;

  /// 虚线的宽度
  final double dashWidth;

  /// 分割线标题
  final dynamic title;

  /// 标题位置
  /// 水平分割线: left=左侧, center=居中, right=右侧
  /// 垂直分割线: left=顶部, center=居中, right=底部
  final CDividerTitlePlacement titlePlacement;

  /// 标题偏移
  /// 当type为horizontal时:
  /// - titlePlacement为left时, 标题左侧的边距
  /// - titlePlacement为center时, 相对于中心的偏移
  /// - titlePlacement为right时, 相对于右侧的偏移
  /// 当type为vertical时:
  /// - titlePlacement为left时, 标题顶部的边距
  /// - titlePlacement为center时, 相对于中心的偏移
  /// - titlePlacement为right时, 相对于底部的偏移
  final double titleOffset;

  /// 标题样式
  final TextStyle? titleStyle;

  /// 标题与线的间距
  final double titleSpacing;

  /// 内边距
  final EdgeInsetsGeometry padding;

  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final lineColor = color ?? Theme.of(context).dividerColor;

    // 如果没有标题，直接返回分割线
    if (title == null) {
      return _buildLine(context, lineColor);
    }

    // 构建标题组件
    Widget titleWidget;
    if (title is Widget) {
      titleWidget = title;
    } else if (title is String) {
      final TextStyle defaultTitleStyle =
          Theme.of(context).textTheme.bodySmall ?? const TextStyle();

      final finalTitleStyle = defaultTitleStyle.merge(
        titleStyle != null ? titleStyle!.copyWith(color: titleColor) : TextStyle(color: titleColor),
      );
      titleWidget = Text(title as String, style: finalTitleStyle);
    } else {
      titleWidget = Text(
        title.toString(),
        style: titleStyle ?? Theme.of(context).textTheme.bodySmall,
      );
    }

    // 根据类型返回不同布局的分割线
    if (type == CDividerType.horizontal) {
      return _buildHorizontalLineWithTitle(context, lineColor, titleWidget);
    } else {
      return _buildVerticalLineWithTitle(context, lineColor, titleWidget);
    }
  }

  /// 构建没有标题的基础分割线
  Widget _buildLine(BuildContext context, Color lineColor) {
    if (type == CDividerType.horizontal) {
      return Container(
        padding: padding,
        width: length,
        height: thickness,
        child: dashed
            ? _buildDashedLine(lineColor, true)
            : Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: lineColor,
                  borderRadius: borderRadius,
                ),
              ),
      );
    } else {
      return Container(
        padding: padding,
        width: thickness,
        height: length,
        child: dashed
            ? _buildDashedLine(lineColor, false)
            : Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: lineColor,
                  borderRadius: borderRadius,
                ),
              ),
      );
    }
  }

  /// 构建虚线
  Widget _buildDashedLine(Color color, bool isHorizontal) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxLength = isHorizontal ? constraints.maxWidth : constraints.maxHeight;
        final int dashCount = (maxLength / (dashWidth + dashGap)).floor();

        return Flex(
          direction: isHorizontal ? Axis.horizontal : Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (index) {
            return Container(
              width: isHorizontal ? dashWidth : thickness,
              height: isHorizontal ? thickness : dashWidth,
              color: color,
            );
          }),
        );
      },
    );
  }

  /// 构建带标题的水平分割线
  Widget _buildHorizontalLineWithTitle(BuildContext context, Color lineColor, Widget titleWidget) {
    final Widget dividerLine = Container(height: thickness, color: lineColor);

    // 虚线分割线
    final Widget dashedDividerLine = SizedBox(
      height: thickness,
      child: _buildDashedLine(lineColor, true),
    );

    // 根据标题位置和偏移量计算
    switch (titlePlacement) {
      case CDividerTitlePlacement.left:
        // 左侧布局: [空白][标题][线]
        return Container(
          padding: padding,
          width: length,
          child: Row(
            children: [
              // 标题左侧的偏移空间
              SizedBox(width: titleOffset),
              // 标题
              titleWidget,
              // 标题与线之间的间距
              SizedBox(width: titleSpacing),
              // 分割线
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
            ],
          ),
        );

      case CDividerTitlePlacement.right:
        // 右侧布局: [线][标题][空白]
        return Container(
          padding: padding,
          width: length,
          child: Row(
            children: [
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
              SizedBox(width: titleSpacing),
              titleWidget,
              SizedBox(width: titleOffset),
            ],
          ),
        );

      case CDividerTitlePlacement.center:
        // 中间布局: [线][标题][线]
        return Container(
          padding: padding,
          width: length,
          child: Row(
            children: [
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
              SizedBox(width: titleSpacing),
              Padding(
                padding: EdgeInsets.only(left: titleOffset),
                child: titleWidget,
              ),
              SizedBox(width: titleSpacing),
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
            ],
          ),
        );
    }
  }

  /// 构建带标题的垂直分割线
  Widget _buildVerticalLineWithTitle(BuildContext context, Color lineColor, Widget titleWidget) {
    final Widget dividerLine = Container(width: thickness, color: lineColor);

    // 虚线分割线
    final Widget dashedDividerLine = SizedBox(
      width: thickness,
      child: _buildDashedLine(lineColor, false),
    );

    // 根据标题位置和偏移量计算
    switch (titlePlacement) {
      case CDividerTitlePlacement.left:
        // 顶部布局: [空白][标题][线]
        return Container(
          padding: padding,
          height: length,
          child: Column(
            children: [
              // 标题顶部的偏移空间
              SizedBox(height: titleOffset),
              // 标题
              titleWidget,
              // 标题与线之间的间距
              SizedBox(height: titleSpacing),
              // 分割线
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
            ],
          ),
        );

      case CDividerTitlePlacement.right:
        // 底部布局: [线][标题][空白]
        return Container(
          padding: padding,
          height: length,
          child: Column(
            children: [
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
              SizedBox(height: titleSpacing),
              titleWidget,
              SizedBox(height: titleOffset),
            ],
          ),
        );

      case CDividerTitlePlacement.center:
        // 中间布局: [线][标题][线]
        return Container(
          padding: padding,
          height: length,
          child: Column(
            children: [
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
              SizedBox(height: titleSpacing),
              Padding(
                padding: EdgeInsets.only(top: titleOffset),
                child: titleWidget,
              ),
              SizedBox(height: titleSpacing),
              Expanded(child: dashed ? dashedDividerLine : dividerLine),
            ],
          ),
        );
    }
  }
}
