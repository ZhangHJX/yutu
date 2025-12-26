import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CSecretCodeInput extends HookWidget {
  CSecretCodeInput({
    super.key,
    this.textStyle,
    this.length = 6,
    this.onCompleted,
    this.autoFocus = false,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.obscureTextStyle,
    this.boxSize,
    this.shouldFocus = false,
  }) : assert(
         boxSize == null || boxSize.width > 0 && boxSize.height > 0,
         'boxSize must be greater than 0',
       );

  /// 显示字体的样式
  final TextStyle? textStyle;

  /// 隐藏密码时的字体样式
  final TextStyle? obscureTextStyle;

  /// 输入框的长度
  final int length;

  /// 输入完成后的回调
  final ValueChanged<String>? onCompleted;

  /// 是否在创建的时候自动聚焦
  final bool autoFocus;

  /// 是否隐藏密码, 默认为false
  final bool obscureText;

  /// 密码的掩码字符, 默认为 •
  final String obscuringCharacter;

  /// 输入框的尺寸, 默认是 46.w x 58.w
  final Size? boxSize;

  /// 是否应该聚焦, 一般就是条件发生改变, 手动聚焦
  final bool shouldFocus;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final codeList = useState(List<String>.filled(length, ''));

    final isFocused = useListenable(focusNode);

    final onChanged = useCallback((String value) {
      final newCodes = List<String>.filled(length, '');
      for (int i = 0; i < length; i++) {
        newCodes[i] = i < value.length ? value[i] : '';
      }

      codeList.value = newCodes;

      if (value.length == length) {
        onCompleted?.call(newCodes.join());
        focusNode.unfocus();
      }
    }, [length, onCompleted]);

    useEffect(() {
      if (shouldFocus) {
        focusNode.requestFocus();
      }
      return null;
    }, [shouldFocus]);

    return DefaultTextStyle(
      style: text333333(fontSize: 32.w, height: 36 / 32).merge(textStyle),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: .spaceAround,
            children: List.generate(length, (index) {
              final isFilled = codeList.value[index].isNotEmpty;
              final isCurrent = !isFilled && (index == 0 || codeList.value[index - 1].isNotEmpty);

              final showCursor = isCurrent && isFocused.hasFocus;

              return AnimatedContainer(
                duration: 250.ms,
                alignment: .center,
                width: boxSize?.width ?? 46.w,
                height: boxSize?.height ?? 58.w,
                decoration: BoxDecoration(
                  border: Border.all(color: showCursor ? '#FFFFAD2B'.color : '#FFD1D1D1'.color),
                  borderRadius: .circular(6.w),
                ),

                child: isFilled
                    ? Text(
                        obscureText ? obscuringCharacter : codeList.value[index],
                        style: obscureTextStyle,
                      )
                    : showCursor
                    ? _BlinkingCursor()
                    : const SizedBox.shrink(),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: CTextField(
                autofocus: autoFocus,
                focusNode: focusNode,
                controller: controller,
                hintText: '',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(length),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Text('|')
        .animate(
          onPlay: (ctr) {
            ctr.repeat();
          },
        )
        .fadeIn(duration: 500.ms)
        .then()
        .fadeOut(duration: 500.ms);
  }
}
