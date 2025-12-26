import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CExpandableText extends HookWidget {
  CExpandableText({
    required this.text,
    required this.textStyle,
    required this.maxLines,
    Widget? expandWidget,
    Widget? collapseWidget,
    this.expandText,
    this.collapseText,
    super.key,
  }) : expandWidget = expandWidget ?? CGradientText(expandText ?? '展开', style: textStyle),
       collapseWidget = collapseWidget ?? CGradientText(collapseText ?? '收起', style: textStyle);

  final String text;
  final int maxLines;
  final TextStyle textStyle;

  /// 展开按钮
  final Widget expandWidget;

  /// 收起按钮
  final Widget collapseWidget;

  /// 展开文本
  final String? expandText;

  /// 收起文本
  final String? collapseText;

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);
    final expandButtonWidth = useState<double>(0);

    if (expanded.value) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text, style: textStyle),
            WidgetSpan(
              alignment: .middle,
              child: GestureDetector(onTap: () => expanded.value = false, child: collapseWidget),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: text, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: maxLines,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return Text(text, style: textStyle);
        }

        final ellipsisWidth = _calculateTextWidth('...', textStyle);

        // 计算适合在最后一行显示的文本长度
        final lastLineTextWidth = constraints.maxWidth - expandButtonWidth.value - ellipsisWidth;

        // 获取文本在指定宽度下可以显示的字符串
        final visibleText = _getVisibleText(
          text,
          textStyle,
          constraints.maxWidth,
          lastLineTextWidth,
          maxLines,
        );

        return GestureDetector(
          onTap: () => expanded.value = !expanded.value,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$visibleText...', style: textStyle),
                WidgetSpan(
                  alignment: .middle,
                  child: CMeasureSize(
                    onChange: (size, _) {
                      expandButtonWidth.value = size.width;
                    },
                    child: expandWidget,
                  ),
                ),
              ],
            ),
            maxLines: maxLines,
          ),
        );
      },
    );
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr, maxLines: 1);
    textPainter.layout();
    return textPainter.width;
  }

  String _getVisibleText(
    String fullText,
    TextStyle style,
    double fullWidth,
    double lastLineAvailableWidth,
    int maxLines,
  ) {
    if (maxLines <= 0) {
      return '';
    }

    // 如果只有1行，简单处理
    if (maxLines == 1) {
      return _getTextForWidth(fullText, style, lastLineAvailableWidth);
    }

    // 对于多行文本，先计算完整的(maxLines-1)行能显示多少文本
    final preLinesPainter = TextPainter(
      text: TextSpan(text: fullText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines - 1,
    );
    preLinesPainter.layout(maxWidth: fullWidth);

    // 获取前(maxLines-1)行的文本结束位置
    final endOffset = preLinesPainter
        .getPositionForOffset(Offset(preLinesPainter.width, preLinesPainter.height))
        .offset;

    // 如果结束位置大于等于文本长度，说明不需要额外处理
    if (endOffset >= fullText.length) {
      return fullText;
    }

    final fullTextChars = fullText.characters;
    String prefixString;
    try {
      prefixString = fullText.substring(0, endOffset);
      prefixString.characters;
    } catch (e) {
      int safeOffset = endOffset;
      while (safeOffset > 0) {
        try {
          prefixString = fullText.substring(0, safeOffset);
          prefixString.characters;
          break;
        } catch (e) {
          safeOffset--;
        }
      }
      prefixString = fullText.substring(0, safeOffset);
    }

    final prefixChars = prefixString.characters;
    final charCount = prefixChars.length;

    final remainingText = fullTextChars.skip(charCount).string;

    final lastLineText = _getTextForWidth(remainingText, style, lastLineAvailableWidth);

    return fullTextChars.take(charCount).string + lastLineText;
  }

  // 计算在给定宽度下可以显示的最大文本
  String _getTextForWidth(String text, TextStyle style, double maxWidth) {
    final textChars = text.characters;

    int low = 0;
    int high = textChars.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      final subText = textChars.take(mid).string;
      final width = _calculateTextWidth(subText, style);

      if (width <= maxWidth) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    final resultLength = low > 0 ? low - 1 : 0;
    return textChars.take(resultLength).string;
  }
}
