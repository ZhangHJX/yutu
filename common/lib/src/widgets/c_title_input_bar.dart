import 'package:common/src/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config/index.dart';
import 'c_text_field.dart';

/// 提示 + 输入框 组合
class CTitleInputBar extends HookWidget {
  const CTitleInputBar({
    required this.hintText,
    required this.title,
    super.key,
    this.onChanged,
    this.showBottomBorder = true,
    this.inputFormatters,
    this.suffix,
    this.initialValue,
    this.onTap,
  });

  final String hintText;
  final String title;
  final bool showBottomBorder;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final String? initialValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    useEffect(() {
      if (initialValue != null) {
        controller.text = initialValue!;
      }
      return null;
    }, [initialValue]);

    return Container(
      height: 55.w,
      decoration: showBottomBorder ? BoxDecoration(border: Border(bottom: borderSide)) : null,
      child: Row(
        children: [
          Row(
            spacing: 2.w,
            children: [
              Text(
                '*',
                style: TextStyle(fontSize: 10.w, height: 1, color: '#FFEA3A45'.color),
              ),
              Text(
                title,
                style: text333333(fontSize: 16.w, height: 22 / 16),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: CTextField(
              showClearButton: !hintText.startsWith('请选择'),
              showCursor: !hintText.startsWith('请选择'),
              readOnly: hintText.startsWith('请选择'),
              controller: controller,
              hintText: hintText,
              hideBorders: true,
              textAlign: TextAlign.right,
              onChanged: onChanged,
              onTap: onTap,
              hintStyle: TextStyle(
                fontSize: 16.w,
                height: 22 / 16,
                color: '#FFBDBDBD'.color,
                fontWeight: FontWeight.w400,
              ),
              inputFormatters: inputFormatters,
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}
