import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../utils/index.dart';

class TextPropertyDialog extends StatefulWidget {
  final VoidCallback? onDeleteText;
  final dynamic editBoxData; // EditBoxData from create_design_model
  final VoidCallback? onPropertyChanged; // 属性改变时的回调

  const TextPropertyDialog({
    super.key,
    this.onDeleteText,
    this.editBoxData,
    this.onPropertyChanged,
  });

  @override
  State<TextPropertyDialog> createState() => _TextPropertyDialogState();
}

class _TextPropertyDialogState extends State<TextPropertyDialog>
    with SingleTickerProviderStateMixin {
  // TabController
  late TabController _tabController;

  // 字体和字号
  String _fontFamily = '系统默认';
  final TextEditingController _fontSizeController = TextEditingController(
    text: '16',
  );

  // 字重和颜色
  String _fontWeight = '系统默认';
  String _textColor = '#000000';
  final TextEditingController _textColorController = TextEditingController(
    text: '#000000',
  );

  // 行距和字距
  double _lineHeight = 1.0;
  double _letterSpacing = 0;

  // 对齐
  TextAlign _textAlign = TextAlign.left;

  // 填充颜色
  String _fillColor1 = '#00CED1';
  final TextEditingController _fillColor1Controller = TextEditingController(
    text: '#00CED1',
  );
  String _fillColor2 = '#FFA500';
  final TextEditingController _fillColor2Controller = TextEditingController(
    text: '#FFA500',
  );
  int _fillStyle = 1;

  // 阴影
  String _shadowColor = '#A020F0';
  final TextEditingController _shadowColorController = TextEditingController(
    text: '#A020F0',
  );
  final TextEditingController _shadowXController = TextEditingController(
    text: '0',
  );
  final TextEditingController _shadowYController = TextEditingController(
    text: '0',
  );
  final TextEditingController _shadowBlurController = TextEditingController(
    text: '0',
  );
  bool _shadowEnabled = false;

  // 下拉列表状态
  bool _showFontFamilyDropdown = false;
  bool _showFontWeightDropdown = false;

  // 字体列表
  final List<String> _fontFamilies = [
    '系统默认',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Verdana',
    'Helvetica',
    'Georgia',
    'Palatino',
  ];

  // 字重列表
  final List<String> _fontWeights = [
    '系统默认',
    'Light',
    'Regular',
    'Medium',
    'Bold',
    'Extra Bold',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFromModel();
  }

  /// 从模型初始化UI状态
  void _initializeFromModel() {
    if (widget.editBoxData == null) return;

    final data = widget.editBoxData;

    // 初始化字体和字号
    _fontFamily = data.fontFamily ?? '系统默认';
    _fontSizeController.text = data.fontSize?.toInt().toString() ?? '16';

    // 初始化字重
    _fontWeight = _fontWeightToString(data.fontWeight);

    // 初始化文字颜色
    _textColor = data.textColor ?? '#000000';
    _textColorController.text = _textColor;

    // 初始化行距和字距
    _lineHeight = data.lineHeight ?? 1.0;
    _letterSpacing = data.fontSpace ?? 0;

    // 初始化对齐方式
    _textAlign = data.align ?? TextAlign.left;

    // 初始化填充颜色
    _fillColor1 = data.fillColor ?? '#00CED1';
    _fillColor1Controller.text = _fillColor1;

    // 初始化描边（对应fillColor2）
    _fillColor2 = data.borderColor ?? '#FFA500';
    _fillColor2Controller.text = _fillColor2;
    _fillStyle = data.borderWidth?.toInt() ?? 1;

    // 初始化阴影
    _shadowEnabled = data.isShawOpen ?? false;
    _shadowColor = data.shawColor ?? '#A020F0';
    _shadowColorController.text = _shadowColor;
    _shadowXController.text = data.shawX?.toString() ?? '0';
    _shadowYController.text = data.shawY?.toString() ?? '0';
    _shadowBlurController.text = data.blurValue?.toString() ?? '0';
  }

  /// 将FontWeight转换为字符串
  String _fontWeightToString(FontWeight? weight) {
    if (weight == null) return '系统默认';
    switch (weight) {
      case FontWeight.w300:
        return 'Light';
      case FontWeight.w400:
        return 'Regular';
      case FontWeight.w500:
        return 'Medium';
      case FontWeight.w700:
        return 'Bold';
      case FontWeight.w800:
        return 'Extra Bold';
      default:
        return '系统默认';
    }
  }

  /// 将字符串转换为FontWeight
  FontWeight _stringToFontWeight(String weight) {
    switch (weight) {
      case 'Light':
        return FontWeight.w300;
      case 'Regular':
        return FontWeight.w400;
      case 'Medium':
        return FontWeight.w500;
      case 'Bold':
        return FontWeight.w700;
      case 'Extra Bold':
        return FontWeight.w800;
      default:
        return FontWeight.w400;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fontSizeController.dispose();
    _textColorController.dispose();
    _fillColor1Controller.dispose();
    _fillColor2Controller.dispose();
    _shadowColorController.dispose();
    _shadowXController.dispose();
    _shadowYController.dispose();
    _shadowBlurController.dispose();
    super.dispose();
  }

  /// 打开颜色选择器
  void _openColorPicker({
    required Color initialColor,
    required ValueChanged<Color> onColorSelected,
  }) async {
    final selectedColor = await showColorPickerDialog(
      context,
      initialColor: initialColor,
    );

    if (selectedColor != null) {
      onColorSelected(selectedColor);
    }
  }

  /// 更新数据模型
  void _updateModel() {
    if (widget.editBoxData == null) return;

    final data = widget.editBoxData;

    // 更新字体和字号
    data.fontFamily = _fontFamily == '系统默认' ? 'Courier' : _fontFamily;
    data.fontSize = double.tryParse(_fontSizeController.text) ?? 16.0;

    // 更新字重
    data.fontWeight = _stringToFontWeight(_fontWeight);

    // 更新文字颜色
    data.textColor = _textColor;

    // 更新行距和字距
    data.lineHeight = _lineHeight;
    data.fontSpace = _letterSpacing;

    // 更新对齐方式
    data.align = _textAlign;

    // 更新填充颜色
    data.fillColor = _fillColor1;

    // 更新描边
    data.borderColor = _fillColor2;
    data.borderWidth = _fillStyle.toDouble();

    // 更新阴影
    data.isShawOpen = _shadowEnabled;
    data.shawColor = _shadowColor;
    data.shawX = double.tryParse(_shadowXController.text) ?? 0.0;
    data.shawY = double.tryParse(_shadowYController.text) ?? 0.0;
    data.blurValue = double.tryParse(_shadowBlurController.text) ?? 0.0;

    // 通知外部属性已更新，触发实时刷新
    widget.onPropertyChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 使用 KeyboardDismissOnTap 包裹，点击外部可关闭键盘
    return KeyboardDismissOnTap(
      // ⭐ 使用 KeyboardVisibilityBuilder 监听键盘状态
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Container(
            width: ScreenTools.screenWidth,
            height: ScreenTools.bottomBarHeight + 320.w,
            // ⭐ 动态底部边距，将整个弹框顶上去
            margin: EdgeInsets.only(
              bottom: ScreenTools.getKeyboardHeight(context, isKeyboardVisible),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.w),
                topRight: Radius.circular(18.w),
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // 标题栏
                    _buildTitleBarWithTabs(),

                    // TabBarView 内容区域
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 文本属性标签页
                          _buildTextPropertyTab(),
                          // 填充标签页
                          _buildFillTab(),
                          // 行距对齐标签页
                          _buildSpacingAlignmentTab(),
                        ],
                      ),
                    ),
                  ],
                ),

                // 字体下拉列表 - 使用 Stack 定位
                if (_showFontFamilyDropdown)
                  Positioned(
                    left: 16.w,
                    top: 150.w, // 根据实际位置调整
                    child: _buildDropdownList(_fontFamilies, _fontFamily, (
                      font,
                    ) {
                      setState(() {
                        _fontFamily = font;
                        _showFontFamilyDropdown = false;
                        _updateModel();
                      });
                    }),
                  ),

                // 字重下拉列表 - 使用 Stack 定位
                if (_showFontWeightDropdown)
                  Positioned(
                    left: 16.w,
                    top: 240.w, // 根据实际位置调整
                    child: _buildDropdownList(_fontWeights, _fontWeight, (
                      weight,
                    ) {
                      setState(() {
                        _fontWeight = weight;
                        _showFontWeightDropdown = false;
                        _updateModel();
                      });
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 标题栏
  Widget _buildTitleBarWithTabs() {
    return Container(
      width: ScreenTools.screenWidth,
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: ScreenTools.screenWidth - 130.w,
            height: 50.w,
            padding: EdgeInsets.only(left: 28.w, top: 10.w),
            child: TabBar(
              controller: _tabController,
              labelColor: "#ff262626".color,
              unselectedLabelColor: "#ff262626".color.withValues(alpha: 0.6),
              labelStyle: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              indicatorPadding: EdgeInsets.zero,
              tabs: [
                Container(
                  width: 64.w,
                  color: Colors.white,
                  child: Tab(text: '文本属性'),
                ),
                Container(
                  width: 64.w,
                  color: Colors.white,
                  child: Tab(text: '效果'),
                ),
                Container(
                  width: 64.w,
                  color: Colors.white,
                  child: Tab(text: '行距对齐'),
                ),
              ],
            ),
          ),

          Spacer(),

          // 关闭按钮
          GestureDetector(
            onTap: () {
              SmartDialog.dismiss();
            },
            child: Container(
              margin: EdgeInsets.only(top: 10.w),
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
          SizedBox(width: 10.w),
        ],
      ),
    );
  }

  // 文本属性标签页
  Widget _buildTextPropertyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 字体和字号
        _buildFontAndSizeSection(),
        SizedBox(height: 17.w),

        // 字重和颜色
        _buildFontWeightAndColorSection(),
        SizedBox(height: 30.w),

        // 删除文本按钮
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildFontAndSizeSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 57.w),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '字体',
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#FF3E3E3E".color.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 6.w),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFontFamilyDropdown = !_showFontFamilyDropdown;
                    _showFontWeightDropdown = false; // 关闭字重下拉
                  });
                },
                child: Container(
                  width: 140.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                    border: BoxBorder.all(color: "#FFE6E6E6".color, width: 1.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 16.w),
                          child: Text(
                            _fontFamily,
                            style: TextStyle(
                              fontSize: 14.w,
                              color: "#ff242424".color,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),

                      Container(
                        width: 36.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: Image.asset(
                              'assets/images/canvals/canvals_text_font_down.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '字号',
                  style: TextStyle(
                    fontSize: 16.w,
                    color: "#FF3E3E3E".color.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 6.w),

                Container(
                  height: 42.w,
                  width: 148.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(
                      color: "#ffE6E6E6".color, // 边框颜色
                      width: 1.w, // 边框宽度
                    ),
                  ),
                  child: TextField(
                    controller: _fontSizeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14.w,
                      color: "#ff242424".color,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                    onChanged: (value) {
                      _updateModel();
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16.w,
                        horizontal: 12.w,
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

  Widget _buildFontWeightAndColorSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 57.w),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '字重',
                style: TextStyle(fontSize: 14.w, color: "#ff999999".color),
              ),

              SizedBox(height: 6.w),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFontWeightDropdown = !_showFontWeightDropdown;
                    _showFontFamilyDropdown = false; // 关闭字体下拉
                  });
                },
                child: Container(
                  height: 42.w,
                  width: 140.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(color: "#FFE6E6E6".color, width: 1.w),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 16.w),
                          child: Text(
                            _fontWeight,
                            style: TextStyle(
                              fontSize: 14.w,
                              color: "#ff242424".color,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),

                      Container(
                        width: 36.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: Image.asset(
                              'assets/images/canvals/canvals_text_font_down.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '字色',
                  style: TextStyle(fontSize: 14.w, color: "#ff999999".color),
                ),

                SizedBox(height: 6.w),

                Container(
                  height: 42.w,
                  width: 148.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(
                      color: "#ffE6E6E6".color, // 边框颜色
                      width: 1.w, // 边框宽度
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 9.w),
                  child: Row(
                    children: [
                      // 颜色预览widget
                      GestureDetector(
                        onTap: () {
                          _openColorPicker(
                            initialColor: _textColor.color,
                            onColorSelected: (color) {
                              setState(() {
                                _textColor = color.string;
                                _textColorController.text = color.string;
                                _updateModel();
                              });
                            },
                          );
                        },
                        child: Container(
                          width: 27.w,
                          height: 27.w,
                          padding: EdgeInsets.only(top: 7.w),
                          decoration: BoxDecoration(
                            color: _textColor.color,
                            borderRadius: BorderRadius.circular(6.w),
                            border: Border.all(
                              color: "#ffE6E6E6".color, // 边框颜色
                              width: 1.w, // 边框宽度
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // 颜色值输入框
                      Expanded(
                        child: SizedBox(
                          height: 42.w,
                          child: TextField(
                            controller: _textColorController,
                            inputFormatters: [HexColorFormatter()],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16.w,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14.w,
                              fontWeight: FontWeight.w500,
                              color: "#ff242424".color,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && value.length == 7) {
                                setState(() {
                                  _textColor = value;
                                  _updateModel();
                                });
                              }
                            },
                          ),
                        ),
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
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: EdgeInsets.only(
        left: 22.w,
        right: 22.w,
        top: 22.w,
        bottom: 22.w,
      ),
      child: GestureDetector(
        onTap: () {
          widget.onDeleteText?.call();
          SmartDialog.dismiss();
        },
        child: Container(
          width: double.infinity,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.w),
            border: Border.all(color: "#FFFF3333".color, width: 1.w),
          ),
          child: Center(
            child: Text(
              '删除文本',
              style: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w500,
                color: "#FFFF3333".color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 填充标签页
  Widget _buildFillTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 填充
        _buildFillSection(),
        SizedBox(height: 18.w),

        // 描边
        _buildBorderSection(),
        SizedBox(height: 7.w),

        // 阴影
        _buildShadowSection(),
      ],
    );
  }

  // 行距对齐标签页
  Widget _buildSpacingAlignmentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行距和字距
          _buildSpacingSection(),
          SizedBox(height: 13.w),

          // 对齐
          _buildAlignmentSection(),
        ],
      ),
    );
  }

  Widget _buildDropdownList(
    List<String> items,
    String selectedItem,
    Function(String) onItemSelected,
  ) {
    return Container(
      width: 200.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.w),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4.w,
            offset: Offset(0, 2.w),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return GestureDetector(
            onTap: () => onItemSelected(item),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 12.w),
              decoration: BoxDecoration(
                color: selectedItem == item
                    ? Colors.blue.shade50
                    : Colors.transparent,
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14.w,
                  color: selectedItem == item ? Colors.blue : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpacingSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 27.w),
      child: Column(
        children: [
          // 行距
          Row(
            children: [
              Text(
                '行距',
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff3E3E3E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),

              Expanded(child: Container()),

              Text(
                _lineHeight.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff007BFE".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: 7.w),
          _buildGradientSlider(
            _lineHeight,
            (value) {
              setState(() {
                _lineHeight = value;
                _updateModel();
              });
            },
            min: 0.0,
            max: 3.0,
          ),

          SizedBox(height: 13.w),

          // 字距
          Row(
            children: [
              Text(
                '字距',
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff3E3E3E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(child: Container()),
              Text(
                _letterSpacing.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff007BFE".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          SizedBox(height: 7.w),

          _buildGradientSlider(
            _letterSpacing,
            (value) {
              setState(() {
                _letterSpacing = value;
                _updateModel();
              });
            },
            min: 0.0,
            max: 5.0,
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '对齐',
            style: TextStyle(
              fontSize: 16.w,
              color: "#ff3E3E3E".color,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 11.w),

          Container(
            width: 171.w,
            height: 59.w,
            padding: EdgeInsets.only(left: 9.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAlignmentButton(
                  TextAlign.left,
                  'assets/images/canvals/canvals_align_left.png',
                  '左对齐',
                ),
                _buildAlignmentButton(
                  TextAlign.center,
                  'assets/images/canvals/canvals_align_middle.png',
                  '居中对齐',
                ),
                _buildAlignmentButton(
                  TextAlign.right,
                  'assets/images/canvals/canvals_align_right.png',
                  '右对齐',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '填充',
            style: TextStyle(
              fontSize: 16.w,
              color: "#ff3E3E3E".color,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(width: 12.w),

          // 上面的颜色输入框 - 固定宽度
          GestureDetector(
            onTap: () {
              _openColorPicker(
                initialColor: _fillColor1.color,
                onColorSelected: (color) {
                  setState(() {
                    _fillColor1 = color.string;
                    _fillColor1Controller.text = color.string;
                    _updateModel();
                  });
                },
              );
            },
            child: Container(
              width: 58.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: _fillColor1.color,
                borderRadius: BorderRadius.circular(18.w),
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // 颜色值输入框
          Container(
            width: 84.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _fillColor1Controller,
              textAlign: TextAlign.center,
              inputFormatters: [HexColorFormatter()],
              onChanged: (value) {
                if (value.isNotEmpty && value.length == 7) {
                  setState(() {
                    _fillColor1 = value;
                    _updateModel();
                  });
                }
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 5.w),
                hintText: '#FFFFFF',
              ),
              style: TextStyle(
                fontSize: 14.w,
                fontWeight: FontWeight.w600,
                color: "#ff242424".color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '描边',
            style: TextStyle(
              fontSize: 16.w,
              color: "#ff3E3E3E".color,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(width: 12.w),

          // 下面的内容：颜色widget、颜色值输入框、边框图标、边框大小输入框
          GestureDetector(
            onTap: () {
              _openColorPicker(
                initialColor: _fillColor2.color,
                onColorSelected: (color) {
                  setState(() {
                    _fillColor2 = color.string;
                    _fillColor2Controller.text = color.string;
                    _updateModel();
                  });
                },
              );
            },
            child: Container(
              width: 58.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: _fillColor2.color,
                borderRadius: BorderRadius.circular(18.w),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // 颜色值输入框
          Container(
            width: 84.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _fillColor2Controller,
              textAlign: TextAlign.center,
              inputFormatters: [HexColorFormatter()],
              onChanged: (value) {
                if (value.isNotEmpty && value.length == 7) {
                  setState(() {
                    _fillColor2 = value;
                    _updateModel();
                  });
                }
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 5.w),
                hintText: '#FFFFFF',
              ),
              style: TextStyle(
                fontSize: 14.w,
                fontWeight: FontWeight.w600,
                color: "#ff242424".color,
              ),
            ),
          ),

          SizedBox(width: 9.w),

          // 边框图标
          Image.asset(
            'assets/images/canvals/canvals_border_icon.png',
            width: 26.w,
            height: 26.w,
            fit: BoxFit.cover,
          ),

          SizedBox(width: 6.w),

          // 边框大小输入框
          Container(
            width: 84.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: TextEditingController(text: _fillStyle.toString()),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                final newValue = int.tryParse(value);
                if (newValue != null) {
                  setState(() {
                    _fillStyle = newValue;
                    _updateModel();
                  });
                }
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              ),
              style: TextStyle(
                fontSize: 14.w,
                fontWeight: FontWeight.w600,
                color: "#ff242424".color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 27.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和启用开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '阴影',
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#ff3E3E3E".color.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _shadowEnabled = !_shadowEnabled;
                    _updateModel();
                  });
                },
                child: Row(
                  children: [
                    // canvals_shaw_unon
                    Image.asset(
                      _shadowEnabled
                          ? 'assets/images/canvals/canvals_shaw_on.png'
                          : 'assets/images/canvals/canvals_shaw_unon.png',
                      width: 14.w,
                      height: 14.w,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _shadowEnabled ? '启用' : "未启用",
                      style: TextStyle(
                        fontSize: 14.w,
                        color: _shadowEnabled
                            ? "#A77AFF".color
                            : "#A4A4A4".color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.w),

          // 颜色预览、输入框、X、Y
          Row(
            children: [
              // 颜色预览框
              GestureDetector(
                onTap: () {
                  _openColorPicker(
                    initialColor: _shadowColor.color,
                    onColorSelected: (color) {
                      setState(() {
                        _shadowColor = color.string;
                        _shadowColorController.text = color.string;
                        _updateModel();
                      });
                    },
                  );
                },
                child: Container(
                  width: 58.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: _shadowColor.color,
                    borderRadius: BorderRadius.circular(18.w),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // 颜色输入框
              Container(
                width: 84.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _shadowColorController,
                  textAlign: TextAlign.center,
                  inputFormatters: [HexColorFormatter()],
                  onChanged: (value) {
                    if (value.isNotEmpty && value.length == 7) {
                      setState(() {
                        _shadowColor = value;
                        _updateModel();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 5.w),
                  ),
                  style: TextStyle(
                    fontSize: 14.w,
                    fontWeight: FontWeight.w600,
                    color: "#ff242424".color,
                  ),
                ),
              ),

              SizedBox(width: 11.w),

              // X 偏移输入框
              Container(
                width: 67.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Text(
                        'X',
                        style: TextStyle(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w600,
                          color: "#ff242424".color,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 5.w),
                        child: TextField(
                          controller: _shadowXController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final x = double.tryParse(value);
                              if (x != null) {
                                _updateModel();
                              }
                            }
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 14.w,
                            fontWeight: FontWeight.w600,
                            color: "#ff242424".color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 9.w),

              // Y 偏移输入框
              Container(
                width: 67.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Text(
                        'Y',
                        style: TextStyle(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w600,
                          color: "#ff242424".color,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 5.w),
                        child: TextField(
                          controller: _shadowYController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final y = double.tryParse(value);
                              if (y != null) {
                                _updateModel();
                              }
                            }
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 14.w,
                            fontWeight: FontWeight.w600,
                            color: "#ff242424".color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 11.w),

          // 模糊输入框
          Container(
            width: 84.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.w),
              border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: Text(
                    '模糊',
                    style: TextStyle(
                      fontSize: 14.w,
                      fontWeight: FontWeight.w600,
                      color: "#ff242424".color,
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: TextField(
                      controller: _shadowBlurController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final blur = double.tryParse(value);
                          if (blur != null) {
                            _updateModel();
                          }
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 14.w,
                        fontWeight: FontWeight.w500,
                        color: "#ff242424".color,
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

  Widget _buildAlignmentButton(
    TextAlign align,
    String imagePath,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _textAlign = align;
          _updateModel();
        });
      },
      child: Column(
        children: [
          Image.asset(imagePath, width: 34.w, height: 34.w, fit: BoxFit.cover),

          Text(
            label,
            style: TextStyle(
              fontSize: 12.w,
              color: "#ff9E9E9E".color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // 创建渐变色滑块
  Widget _buildGradientSlider(
    double value,
    Function(double) onChanged, {
    double min = 0.0,
    double max = 1.0,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算滑块的位置百分比
        final double percentage = (value - min) / (max - min);
        final double trackWidth = constraints.maxWidth;

        return SizedBox(
          height: 30.w,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8.w,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.w),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
              thumbColor: Colors.white,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              trackShape: _CustomSliderTrackShape(),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 完整的渐变色背景
                Container(
                  height: 8.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.w),
                    gradient: LinearGradient(
                      colors: ["#ffC86CFF".color, "#ff5B98FF".color],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                // 灰色背景部分（滑块右侧）- 覆盖在渐变色上
                Positioned(
                  left: percentage * trackWidth,
                  right: 0,
                  child: Container(
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: "#ffE0E0E0".color,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4.w),
                        bottomRight: Radius.circular(4.w),
                      ),
                    ),
                  ),
                ),
                // 滑块本身
                Slider(value: value, min: min, max: max, onChanged: onChanged),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 自定义滑块轨道形状，移除所有默认padding
class _CustomSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    // 不绘制任何内容，因为我们使用Stack中的自定义背景
  }
}
