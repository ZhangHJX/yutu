import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../widgets/slider_input_field.dart';
import '../../../model/index.dart';
import '../../../pages/canvals/canvals_controller.dart';
import 'package:voicetemplate/pages/widgets/index.dart';

class ImagePropertyDialog extends StatefulWidget {
  final CanvasElement? element;
  final Function(bool notify)? onValueChanged;
  final VoidCallback? onDeleteImage;
  final VoidCallback replaceImage;
  final BuildContext currentContext;
  const ImagePropertyDialog(
    this.currentContext, {
    super.key,
    this.element,
    this.onValueChanged,
    this.onDeleteImage,
    required this.replaceImage,
  });

  @override
  State<ImagePropertyDialog> createState() => _ImagePropertyDialogState();
}

class _ImagePropertyDialogState extends State<ImagePropertyDialog> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _imagePath;
  double? _imageWidth;
  double? _imageHeight;
  double _imageAlpha = 1.0;

  late CanvalsController _controller;

  @override
  void initState() {
    super.initState();
    _initializeFromModel();
    _controller = Get.find<CanvalsController>();
  }

  void _initializeFromModel() {
    _widthController.text = widget.element?.width.toInt().toString() ?? "200";
    _heightController.text = widget.element?.height.toInt().toString() ?? "200";
    _imagePath = widget.element?.filePath;
    _imageWidth = widget.element?.width;
    _imageHeight = widget.element?.height;
    _imageAlpha = widget.element?.fileAlpha ?? 1.0;
  }

  void _updateModel({bool notify = true}) {
    widget.element?.width = _imageWidth ?? 0.0;
    widget.element?.height = _imageHeight ?? 0.0;
    widget.element?.fileAlpha = _imageAlpha;
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      widget.element?.filePath = _imagePath!;
    }
    widget.onValueChanged?.call(notify);
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
                                  inputFormatters: [
                                    RangeIntFormatter(
                                      min: 0,
                                      max: (_controller.canvasModel.width * 2)
                                          .toInt(),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    final width = double.tryParse(value);
                                    debugPrint("==哈哈哈哈===$width====");
                                    setState(() {
                                      _imageWidth = width;
                                      _updateModel();
                                    });
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
                                  inputFormatters: [
                                    RangeIntFormatter(
                                      min: 0,
                                      max: (_controller.canvasModel.height * 2)
                                          .toInt(),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    final height = double.tryParse(value);
                                    setState(() {
                                      _imageHeight = height;
                                      _updateModel();
                                    });
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

                  SizedBox(height: 12.w),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SliderInputField(
                      title: '图片透明度',
                      value: _imageAlpha,
                      minValue: 0.0,
                      maxValue: 1.0,
                      trackHeight: 8.w,
                      thumbSize: 16.w,
                      formatter: (value) => '${(value * 100).toInt()}%',
                      parser: (text) =>
                          double.tryParse(text.replaceAll('%', '')) ??
                          0.0 / 100.0,
                      onChanged: (value) {
                        setState(() {
                          _imageAlpha = value;
                          // 滑动过程中只更新模型，不记录命令
                          _updateModel(notify: false);
                        });
                      },
                      onChangeEnd: (value) {
                        // 滑动结束时记录命令
                        _updateModel(notify: true);
                      },
                    ),
                  ),

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
                    widget.replaceImage.call();
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
        SizedBox(height: ScreenTools.bottomBarHeight + 34.w),
      ],
    );
  }
}
