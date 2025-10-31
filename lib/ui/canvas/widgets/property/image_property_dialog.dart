import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class ImagePropertyDialog extends StatefulWidget {
  final String? imagePath;
  final double? currentWidth;
  final double? currentHeight;
  final Function(double width, double height)? onSizeChanged;
  final VoidCallback? onReplaceImage;
  final VoidCallback? onDeleteImage;

  const ImagePropertyDialog({
    super.key,
    this.imagePath,
    this.currentWidth,
    this.currentHeight,
    this.onSizeChanged,
    this.onReplaceImage,
    this.onDeleteImage,
  });

  @override
  State<ImagePropertyDialog> createState() => _ImagePropertyDialogState();
}

class _ImagePropertyDialogState extends State<ImagePropertyDialog> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.currentWidth?.toInt().toString() ?? '200',
    );
    _heightController = TextEditingController(
      text: widget.currentHeight?.toInt().toString() ?? '200',
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 使用 KeyboardDismissOnTap 包裹，点击外部可关闭键盘
    return KeyboardDismissOnTap(
      // ⭐ 使用 KeyboardVisibilityBuilder 监听键盘状态
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
                topLeft: Radius.circular(18.w),
                topRight: Radius.circular(18.w),
              ),
              boxShadow: [
                BoxShadow(
                  color: "#FFCDE4FF".color,
                  blurRadius: 5.w,
                  offset: Offset(0, 1.w),
                ),
              ],
            ),
            // ⭐ 添加 SingleChildScrollView 使内容可滚动
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Container(
                    padding: EdgeInsets.only(bottom: 15.w),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 17.w),
                            child: Text(
                              '图片属性',
                              style: TextStyle(
                                fontSize: 18.w,
                                fontWeight: FontWeight.w500,
                                color: "#ff262626".color,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          right: 10.w,
                          top: 12.w,
                          child: GestureDetector(
                            onTap: () {
                              SmartDialog.dismiss();
                            },
                            child: SizedBox(
                              width: 35.w,
                              height: 35.w,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/canvals/canvals_close_icon.png',
                                  width: 12.w,
                                  height: 12.w,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 尺寸输入区域
                  Container(
                    margin: EdgeInsets.only(top: 18.w),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        // 宽度输入
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '宽度',
                                style: TextStyle(
                                  fontSize: 16.w,
                                  color: "#FF3E3E3E".color,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(height: 6.w),
                              Container(
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18.w),
                                  border: Border.all(
                                    color: "#FFE6E6E6".color,
                                    width: 1.w,
                                  ),
                                ),
                                child: TextField(
                                  controller: _widthController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final width = double.tryParse(value);
                                    final height = double.tryParse(
                                      _heightController.text,
                                    );
                                    if (width != null &&
                                        height != null &&
                                        width > 0 &&
                                        height > 0) {
                                      widget.onSizeChanged?.call(width, height);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '如:200',
                                    hintStyle: TextStyle(
                                      fontSize: 14.w,
                                      color: "#FF999999".color,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 15.w,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // X 分隔符
                        Container(
                          margin: EdgeInsets.only(
                            left: 16.w,
                            right: 16.w,
                            top: 30.w,
                          ),
                          child: Text(
                            '×',
                            style: TextStyle(
                              fontSize: 20.w,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),

                        // 高度输入
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '高度',
                                style: TextStyle(
                                  fontSize: 16.w,
                                  color: "#FF3E3E3E".color,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(height: 6.w),
                              Container(
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18.w),
                                  border: Border.all(
                                    color: "#FFE6E6E6".color,
                                    width: 1.w,
                                  ),
                                ),
                                child: TextField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final height = double.tryParse(value);
                                    final width = double.tryParse(
                                      _widthController.text,
                                    );
                                    if (width != null &&
                                        height != null &&
                                        width > 0 &&
                                        height > 0) {
                                      widget.onSizeChanged?.call(width, height);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '如:200',
                                    hintStyle: TextStyle(
                                      fontSize: 14.w,
                                      color: "#FF999999".color,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 15.w,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.w),

                  // 操作按钮区域
                  _buildBottomButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 25.w, top: 26.w, right: 24.w),
          height: 66.w,
          child: Row(
            children: [
              // 替换按钮
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onReplaceImage?.call();
                    SmartDialog.dismiss();
                  },
                  child: Image.asset(
                    'assets/images/canvals/canvals_replace_icon.png',
                    width: 153.w,
                    height: 40.w,
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              SizedBox(width: 20.w),

              // 删除按钮
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onDeleteImage?.call();
                    SmartDialog.dismiss();
                  },
                  child: Image.asset(
                    'assets/images/canvals/canvals_delete_icon.png',
                    width: 153.w,
                    height: 40.w,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 底部安全区域
        SizedBox(height: ScreenTools.bottomBarHeight),
      ],
    );
  }
}
