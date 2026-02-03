import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/cupertino.dart' show CupertinoTextField;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

/// HSV颜色选择器对话框
class ColorPickerDialog extends StatefulWidget {
  /// 初始颜色
  final Color initialColor;

  /// 颜色改变回调
  final ValueChanged<Color>? onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.onColorChanged,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _currentColor;
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    textController = TextEditingController(text: _currentColor.string);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          // 根据键盘是否可见动态计算底部边距
          final keyboardHeight = isKeyboardVisible
              ? MediaQuery.of(context).viewInsets.bottom
              : 0.0;
          return Container(
            width: ScreenTools.screenWidth,
            // ⭐ 动态调整底部边距，避免被键盘遮挡
            margin: EdgeInsets.only(bottom: keyboardHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.w),
                topRight: Radius.circular(16.w),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: "#ffE6E6E6".color, width: 1.w),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择颜色',
                        style: TextStyle(
                          fontSize: 18.w,
                          fontWeight: FontWeight.w600,
                          color: "#ff262626".color,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onColorChanged?.call(_currentColor);
                          SmartDialog.dismiss(result: _currentColor);
                        },
                        child: Icon(
                          Icons.close,
                          size: 24.w,
                          color: "#ff999999".color,
                        ),
                      ),
                    ],
                  ),
                ),

                // 颜色选择器
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16.w),
                  child: Column(
                    children: [
                      ColorPicker(
                        pickerColor: _currentColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            _currentColor = color;
                          });
                        },
                        colorPickerWidth: ScreenTools.screenWidth - 32.w,
                        pickerAreaHeightPercent: 0.5,
                        enableAlpha: false,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsvWithHue,
                        labelTypes: const [],
                        pickerAreaBorderRadius: BorderRadius.all(
                          Radius.circular(10.w),
                        ),
                        hexInputController: textController,
                        portraitOnly: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: CupertinoTextField(
                          controller: textController,
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.tag),
                          ),
                          suffix: IconButton(
                            icon: const Icon(Icons.content_paste_rounded),
                            onPressed: () =>
                                copyToClipboard(textController.text),
                          ),
                          maxLength: 9,
                          inputFormatters: [
                            UpperCaseTextFormatter(),
                            FilteringTextInputFormatter.allow(
                              RegExp(kValidHexPattern),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 显示颜色选择器对话框的便捷方法
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
  ValueChanged<Color>? onColorChanged,
}) {
  return SmartDialog.show<Color>(
    builder: (context) => ColorPickerDialog(
      initialColor: initialColor,
      onColorChanged: onColorChanged,
    ),
    alignment: Alignment.bottomCenter,
    maskColor: Colors.black.withValues(alpha: .5),
    clickMaskDismiss: false,
  );
}

void copyToClipboard(String input) {
  String textToCopy = input.replaceFirst('#', '').toUpperCase();
  if (textToCopy.startsWith('FF') && textToCopy.length == 8) {
    textToCopy = textToCopy.replaceFirst('FF', '');
  }
  Clipboard.setData(ClipboardData(text: '#$textToCopy'));
}
