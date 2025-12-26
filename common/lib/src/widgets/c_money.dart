import 'package:common/src/entry.dart';
import 'package:flutter/material.dart';

/// 金额组件
/// 默认是12px, 18px, 13px
class CMoney extends StatelessWidget {
  CMoney({
    required this.money,
    this.tip,
    super.key,
    double? symbolSize,
    double? integerSize,
    double? fractionSize,
    this.lineHeight,
    this.color = const Color(0xFFEA3A45),
    this.fontWeight = .w500,
    this.size,
    this.hideSymbol = false,
    this.isGoldWeight = false,
    this.baseline = true,
  }) : symbolSize = symbolSize ?? 12.w,
       integerSize = integerSize ?? 18.w,
       fractionSize = fractionSize ?? 13.w;

  /// 金额, 可以接收String 或  num 类型
  final Object? money;

  /// 提示文字
  final String? tip;

  /// 符号的字体大小, 12
  final double symbolSize;

  /// 行高, 1
  final double? lineHeight;

  /// 整数字体大小, 18
  final double integerSize;

  /// 小数字体大小, 13
  final double fractionSize;

  /// 统一设置整体字体大小
  final double? size;

  /// 文本颜色, 默认为[Color(0xFFEA3A45)]
  final Color color;

  /// 文本字体粗细, 默认为[.w500]
  final FontWeight fontWeight;

  /// 是否隐藏符号, 默认为false
  final bool hideSymbol;

  /// 是否是黄金重量, 默认为false
  final bool isGoldWeight;

  /// 是否是基线对齐, 默认为false
  final bool baseline;

  @override
  Widget build(BuildContext context) {
    if (money == null) {
      return Text(
        tip ?? '暂无定价',
        style: .new(fontWeight: fontWeight, height: lineHeight, color: color),
      );
    }
    // 如果是num类型, 则要先转为String类型, 之后小数点分割, 小数点归为小数部分, 其余归为整数部分
    final moneyString = money is num ? money.toString() : money as String;
    final moneyList = moneyString.split('.');
    final integer = moneyList[0];
    final fraction = moneyList.length > 1
        ? '.${moneyList[1].padRight(isGoldWeight ? 3 : 2, '0')}'
        : (isGoldWeight ? '.000' : '.00');

    return DefaultTextStyle(
      style: .new(fontWeight: fontWeight, height: lineHeight, color: color),
      child: Row(
        mainAxisSize: .min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: .baseline,
        children: [
          if (!hideSymbol && !isGoldWeight)
            Text(
              '￥',
              style: .new(fontSize: size ?? symbolSize, fontWeight: fontWeight, color: color),
            ),
          Text(integer, style: .new(fontSize: size ?? integerSize)),
          Text(fraction, style: .new(fontSize: size ?? fractionSize)),
          if (!hideSymbol && isGoldWeight) Text('g', style: .new(fontSize: size ?? fractionSize)),
        ],
      ),
    );
  }
}
