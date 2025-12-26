import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FocusChangeCallback = Function(bool hasFocus);

class CTextField extends HookWidget {
  const CTextField({
    required this.controller,
    required this.hintText,
    super.key,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.extraSuffixIcon,
    this.showClearButton = true,
    this.onClear,
    this.contentPadding,
    this.enabled = true,
    this.border,
    this.focusedBorder,
    this.enabledBorder,
    this.style,
    this.hintStyle,
    this.isDense,
    this.textAlign = TextAlign.start,
    this.onTap,
    this.onTapOutside,
    this.showCursor,
    this.readOnly = false,
    this.autoUnfocus = true,
    this.autofocus = false,
    this.hideBorders = false,
    this.maxLines,
    this.onFocusChange,
    this.enableInteractiveSelection = true,
    this.maxLength,
    this.showCounter = false,
    this.expands = false,
  });

  final TextEditingController controller;

  final String hintText;

  final bool expands;

  final FocusNode? focusNode;

  final TextInputType keyboardType;

  final TextInputAction textInputAction;

  final bool obscureText;

  final List<TextInputFormatter>? inputFormatters;

  final ValueChanged<String>? onChanged;

  final ValueChanged<String>? onSubmitted;

  final Widget? prefixIcon;

  /// 额外的后缀图标, 在清除按钮后显示, 比如 '获取验证码'
  final Widget? extraSuffixIcon;

  final bool showClearButton;

  final VoidCallback? onClear;

  final VoidCallback? onTap;

  final bool autoUnfocus;

  final VoidCallback? onTapOutside;

  final EdgeInsets? contentPadding;

  final bool enabled;

  final InputBorder? border;

  final bool? showCursor;

  final bool readOnly;

  final InputBorder? focusedBorder;

  final InputBorder? enabledBorder;

  final TextStyle? style;

  final TextStyle? hintStyle;

  final bool? isDense;

  final TextAlign textAlign;

  final bool autofocus;

  /// 是否隐藏边框, 默认false
  final bool hideBorders;

  final int? maxLines;

  final FocusChangeCallback? onFocusChange;

  final bool enableInteractiveSelection;

  final int? maxLength;

  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final finalFocusNode = focusNode ?? useFocusNode();

    final isFocused = useState(false);

    useEffect(() {
      void handleFocusChange() {
        final hasFocus = finalFocusNode.hasFocus;
        isFocused.value = hasFocus;
        onFocusChange?.call(hasFocus);
      }

      finalFocusNode.addListener(handleFocusChange);
      return () => finalFocusNode.removeListener(handleFocusChange);
    }, [finalFocusNode]);

    void handleTextChanged(String value) {
      onChanged?.call(value);
    }

    Widget clearButton() => CButton.icon(
      child: Image.asset('assets/images/login/ic_clear.png', width: 24.w, height: 24.w),
      onPressed: () {
        controller.clear();
        onClear?.call();
        handleTextChanged('');
      },
    );

    final text = useValueListenable(controller).text;

    final finalHintStyle = Theme.of(context).inputDecorationTheme.hintStyle?.merge(hintStyle);

    final suffixIcon = useMemoized(() {
      if (isFocused.value && text.isNotEmpty) {
        return Row(
          mainAxisSize: .min,
          children: [
            if (showClearButton) clearButton(),
            if (extraSuffixIcon != null) extraSuffixIcon!,
          ],
        );
      } else if (extraSuffixIcon != null) {
        return extraSuffixIcon;
      }
      return const SizedBox.shrink();
    }, [isFocused.value, text, showClearButton, extraSuffixIcon]);

    return TextField(
      onTapOutside: (event) {
        if (autoUnfocus) {
          FocusScope.of(context).unfocus();
        }
        onTapOutside?.call();
      },
      enableInteractiveSelection: enableInteractiveSelection,
      textAlign: textAlign,
      onTap: onTap,
      style: style,
      autofocus: autofocus,
      controller: controller,
      focusNode: finalFocusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      showCursor: showCursor,
      readOnly: readOnly,
      textInputAction: textInputAction,
      enabled: enabled,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      expands: expands,
      maxLength: maxLength,
      decoration: InputDecoration(
        counter: showCounter ? null : SizedBox.shrink(),
        prefixIcon: prefixIcon,
        prefixIconConstraints: BoxConstraints(minHeight: prefixIcon == null ? 0 : 24.w),
        suffixIconConstraints: BoxConstraints(minHeight: suffixIcon == null ? 0 : 24.w),
        hintText: hintText,
        hintStyle: finalHintStyle,
        contentPadding: contentPadding,
        suffixIcon: suffixIcon,
        border: hideBorders ? InputBorder.none : border,
        focusedBorder: hideBorders ? InputBorder.none : focusedBorder,
        enabledBorder: hideBorders ? InputBorder.none : enabledBorder,
        isDense: isDense,
      ),
      onChanged: handleTextChanged,
      onSubmitted: onSubmitted,
    );
  }
}
