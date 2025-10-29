import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
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
                    SmartDialog.dismiss();
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
            padding: EdgeInsets.all(16.w),
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (Color color) {
                setState(() {
                  _currentColor = color;
                });
              },
              colorPickerWidth: 280.w,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
              labelTypes: const [],
              pickerAreaBorderRadius: BorderRadius.circular(8.w),
            ),
          ),

          // 颜色预览和Hex值
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            margin: EdgeInsets.only(bottom: 16.w),
            child: Row(
              children: [
                // 颜色预览
                Container(
                  width: 60.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: BorderRadius.circular(8.w),
                    border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
                  ),
                ),

                SizedBox(width: 12.w),

                // Hex值显示
                Expanded(
                  child: Container(
                    height: 50.w,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: "#ffF5F5F5".color,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Center(
                      child: Text(
                        _currentColor.string,
                        style: TextStyle(
                          fontSize: 16.w,
                          fontWeight: FontWeight.w600,
                          color: "#ff242424".color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 按钮组
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            margin: EdgeInsets.only(bottom: 16.w),
            child: Row(
              children: [
                // 取消按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      SmartDialog.dismiss();
                    },
                    child: Container(
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.w),
                        border: Border.all(
                          color: "#ffE6E6E6".color,
                          width: 1.w,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 16.w,
                            fontWeight: FontWeight.w500,
                            color: "#ff666666".color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // 确认按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onColorChanged?.call(_currentColor);
                      SmartDialog.dismiss(result: _currentColor);
                    },
                    child: Container(
                      height: 44.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: ["#ff6C63FF".color, "#ffA77AFF".color],
                        ),
                        borderRadius: BorderRadius.circular(22.w),
                      ),
                      child: Center(
                        child: Text(
                          '确认',
                          style: TextStyle(
                            fontSize: 16.w,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    alignment: Alignment.center,
    maskColor: Colors.black.withValues(alpha: .5),
    clickMaskDismiss: false,
  );
}
