import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 字体属性组件
class TextPropertyWidget extends StatefulWidget {
  final dynamic element;
  final Function(bool notify)? onPropertyChanged;
  final VoidCallback? onDeleteText;
  final Function(String, String, FontWeight) onFontChanged;
  final Function(String) onColorChanged;

  const TextPropertyWidget({
    super.key,
    required this.element,
    this.onPropertyChanged,
    this.onDeleteText,
    required this.onFontChanged,
    required this.onColorChanged,
  });

  @override
  State<TextPropertyWidget> createState() => _TextPropertyWidgetState();
}

class _TextPropertyWidgetState extends State<TextPropertyWidget> {
  // 字体和字号
  String _fontFamily = '系统默认';
  final TextEditingController _fontSizeController = TextEditingController(
    text: '16',
  );

  // 字重
  String _fontWeight = '系统默认';

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
    _initializeFromModel();
  }

  /// 从模型初始化UI状态
  void _initializeFromModel() {
    if (widget.element == null) return;

    final data = widget.element;

    // 初始化字体和字号
    _fontFamily = data.fontFamily ?? '系统默认';
    _fontSizeController.text = data.fontSize?.toInt().toString() ?? '16';

    // 初始化字重
    _fontWeight = _fontWeightToString(data.fontWeight);
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
    _fontSizeController.dispose();
    super.dispose();
  }

  void _updateModel({bool notify = true}) {
    widget.onFontChanged(
      _fontFamily == '系统默认' ? 'Courier' : _fontFamily,
      _fontSizeController.text,
      _stringToFontWeight(_fontWeight),
    );
    widget.onPropertyChanged?.call(notify);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.w),
            // 字体和字号
            _buildFontAndSizeSection(),
            SizedBox(height: 17.w),

            // 字重和颜色
            _buildFontWeightAndColorSection(),
            SizedBox(height: 20.w),

            // 删除文本按钮
            _buildDeleteButton(),

            SizedBox(height: ScreenTools.bottomBarHeight + 15.w),
          ],
        ),

        // 字体下拉列表
        if (_showFontFamilyDropdown)
          Positioned(
            left: 16.w,
            top: 130.w,
            child: _buildDropdownList(165.w, _fontFamilies, _fontFamily, (
              font,
            ) {
              setState(() {
                _fontFamily = font;
                _showFontFamilyDropdown = false;
                _updateModel();
              });
            }),
          ),

        // 字重下拉列表
        if (_showFontWeightDropdown)
          Positioned(
            left: 20.w,
            top: 210.w,
            child: _buildDropdownList(100.w, _fontWeights, _fontWeight, (
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
    );
  }

  // 字体
  Widget _buildFontAndSizeSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 30.w),
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

  // 字重
  Widget _buildFontWeightAndColorSection() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 30.w),
      child: Column(
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
                debugPrint("----还剩多少---$_showFontWeightDropdown---");
              });
            },
            child: Container(
              height: 42.w,
              width: double.infinity,
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
    );
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: EdgeInsets.only(left: 22.w, right: 22.w, top: 12.w),
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

  Widget _buildDropdownList(
    double height,
    List<String> items,
    String selectedItem,
    Function(String) onItemSelected,
  ) {
    return Container(
      width: 125.w,
      height: height,
      padding: EdgeInsets.only(top: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.w),
        boxShadow: [
          BoxShadow(
            color: "#CDE4FF".color,
            blurRadius: 5.w,
            offset: Offset(0, 1.w),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onItemSelected(item),
            child: Container(
              width: 108.w,
              margin: EdgeInsets.only(left: 7.w, right: 7.w, top: 7.w),
              decoration: BoxDecoration(
                color: selectedItem == item ? "#DCEDFE".color : "#FFFFFF".color,
                borderRadius: BorderRadius.all(Radius.circular(8.w)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5.w),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14.w,
                    fontWeight: FontWeight.w400,
                    color: selectedItem == item
                        ? "#3C7BFF ".color
                        : "#727272".color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
