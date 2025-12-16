import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'text_property_controller.dart';

/// 字体数据模型
class FontItem {
  final String id;
  final String name;
  final String fontFamily;
  final bool isRecommended;
  final bool isDownloaded;
  final String? downloadUrl;

  FontItem({
    required this.id,
    required this.name,
    required this.fontFamily,
    this.isRecommended = false,
    this.isDownloaded = true,
    this.downloadUrl,
  });
}

/// 字体属性组件
class TextPropertyWidget extends StatefulWidget {
  final dynamic element;
  final Function(bool notify)? onPropertyChanged;
  final VoidCallback? onDeleteText;
  final Function(String, String, FontWeight) onFontChanged;
  final Function(String) onColorChanged;

  /// 字体列表数据（可从接口获取）
  final List<FontItem>? fontList;

  const TextPropertyWidget({
    super.key,
    required this.element,
    this.onPropertyChanged,
    this.onDeleteText,
    required this.onFontChanged,
    required this.onColorChanged,
    this.fontList,
  });

  @override
  State<TextPropertyWidget> createState() => _TextPropertyWidgetState();
}

class _TextPropertyWidgetState extends State<TextPropertyWidget>
    with SingleTickerProviderStateMixin {
  // 字体和字号
  String _fontFamily = '系统默认';
  final TextEditingController _fontSizeController = TextEditingController(
    text: '16',
  );

  // 字重
  String _fontWeight = '系统默认';

  // Tab控制器
  late TabController _tabController;

  // 字体列表
  late List<FontItem> _allFonts;
  late List<FontItem> _recommendedFonts;

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
    _initializeFonts();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFromModel();
  }

  /// 初始化字体列表
  void _initializeFonts() {
    if (widget.fontList != null && widget.fontList!.isNotEmpty) {
      _allFonts = widget.fontList!;
      _recommendedFonts = widget.fontList!
          .where((font) => font.isRecommended)
          .toList();
    } else {
      // 默认字体列表
      _allFonts = [
        FontItem(
          id: '1',
          name: '系统默认',
          fontFamily: 'Courier',
          isRecommended: true,
        ),
        FontItem(
          id: '2',
          name: 'Arial',
          fontFamily: 'Arial',
          isRecommended: true,
        ),
        FontItem(
          id: '3',
          name: 'Times New Roman',
          fontFamily: 'Times New Roman',
          isRecommended: true,
        ),
        FontItem(id: '4', name: 'Courier New', fontFamily: 'Courier New'),
        FontItem(id: '5', name: 'Verdana', fontFamily: 'Verdana'),
        FontItem(id: '6', name: 'Helvetica', fontFamily: 'Helvetica'),
        FontItem(id: '7', name: 'Georgia', fontFamily: 'Georgia'),
        FontItem(id: '8', name: 'Palatino', fontFamily: 'Palatino'),
        FontItem(
          id: '3',
          name: 'Times New Roman',
          fontFamily: 'Times New Roman',
          isRecommended: true,
        ),

        FontItem(
          id: '3',
          name: 'Times New Roman',
          fontFamily: 'Times New Roman',
          isRecommended: true,
        ),
        FontItem(
          id: '3',
          name: 'Times New Roman',
          fontFamily: 'Times New Roman',
          isRecommended: true,
        ),
      ];
      _recommendedFonts = _allFonts.where((f) => f.isRecommended).toList();
    }
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
    _tabController.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5.w),
        // 字体选择区域（Tabs + 字体列表）
        _buildFontSelectionSection(),
        SizedBox(height: 20.w),
        // 字重和字号
        _buildFontWeightAndSizeSection(),
        SizedBox(height: 20.w),
        // 删除文本按钮
        _buildDeleteButton(),
        SizedBox(height: ScreenTools.bottomBarHeight + 15.w),
      ],
    );
  }

  /// 构建字体选择区域（Tabs + 字体列表）
  Widget _buildFontSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 28.w),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            // ✅ 指示器居中：不要用不对称 indicatorPadding
            indicatorPadding: EdgeInsets.zero,
            // ✅ Tab 间距放这里（推荐）
            labelPadding: EdgeInsets.only(right: 24.w),
            indicator: TabBarUnderlineIndicator(
              width: 13.w,
              height: 2.w,
              color: "#9082FF".color,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            dividerColor: Colors.transparent,
            labelColor: "#262626".color,
            unselectedLabelColor: "#999999".color.withValues(alpha: 0.4),
            labelStyle: TextStyle(fontSize: 14.w, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.w,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: '推荐字体'),
              Tab(text: '全部字体'),
            ],
          ),
        ),
        SizedBox(height: 12.w),
        // 字体列表
        SizedBox(
          height: 211.w, // 固定高度，可根据需要调整
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // ✅ 禁止拖动
            children: [
              _buildFontList(_recommendedFonts),
              _buildFontList(_allFonts),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建字体列表（每行3个）
  Widget _buildFontList(List<FontItem> fonts) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 12.w,
          childAspectRatio: 1.557,
        ),
        itemCount: fonts.length,
        itemBuilder: (context, index) {
          final font = fonts[index];
          final isSelected =
              _fontFamily == font.fontFamily ||
              (_fontFamily == '系统默认' && font.fontFamily == 'Courier');
          return _buildFontItem(font, isSelected);
        },
      ),
    );
  }

  /// 构建单个字体项
  Widget _buildFontItem(FontItem font, bool isSelected) {
    return Column(
      children: [
        // 字体预览按钮
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _fontFamily = font.fontFamily;
                _updateModel();
              });
            },
            child: SelectItemGradientBorder(
              isSelected: isSelected,
              radius: 12.w,
              borderWidth: 1.6.w,
              unselectedBorderColor: Colors.transparent,
              unselectedBorderWidth: 0,
              selectedGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ["#C86CFF".color, "#5B98FF".color],
              ),
              child: Stack(
                children: [
                  // 字体预览文字
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        '示例文字',
                        style: TextStyle(
                          fontSize: 14.w,
                          fontFamily: font.fontFamily == 'Courier'
                              ? null
                              : font.fontFamily,
                          color: isSelected ? "#3C7BFF".color : "#242424".color,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // 下载图标（如果需要下载）
                  if (!font.isDownloaded && font.downloadUrl != null)
                    Positioned(
                      top: 4.w,
                      right: 4.w,
                      child: Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          color: "#3C7BFF".color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.download,
                          size: 12.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 4.w),
        Text(
          font.name,
          style: TextStyle(fontSize: 12.w, color: "#232535".color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 构建字重和字号区域
  /// 构建字重和字号区域（修复：Row 内无限宽/约束问题）
  Widget _buildFontWeightAndSizeSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _LabeledField(
              title: '字重',
              child: InkWell(
                borderRadius: BorderRadius.circular(12.w),
                onTap: () {
                  // _showFontWeightDialog(context);
                },
                child: Container(
                  height: 42.w,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(color: "#FFE6E6E6".color, width: 1.w),
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14.w,
                        color: "#999999".color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _LabeledField(
              title: '字号',
              child: Container(
                height: 42.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: "#ffE6E6E6".color, width: 1.w),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _fontSizeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [
                    // FilteringTextInputFormatter.digitsOnly,
                    // LengthLimitingTextInputFormatter(3),
                  ],
                  textAlign: TextAlign.left,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    fontSize: 14.w,
                    color: "#ff242424".color,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  onChanged: (_) => _updateModel(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示字重选择对话框
  void _showFontWeightDialog(BuildContext buildContext) {
    if (!mounted) return;
    showModalBottomSheet<dynamic>(
      context: buildContext,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.w),
              child: Text(
                '选择字重',
                style: TextStyle(
                  fontSize: 16.w,
                  fontWeight: FontWeight.w600,
                  color: "#242424".color,
                ),
              ),
            ),
            Divider(height: 1.w),
            ..._fontWeights.map(
              (weight) => ListTile(
                title: Text(
                  weight,
                  style: TextStyle(
                    fontSize: 14.w,
                    color: _fontWeight == weight
                        ? "#3C7BFF".color
                        : "#242424".color,
                    fontWeight: _fontWeight == weight
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _fontWeight = weight;
                    _updateModel();
                  });
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            SizedBox(height: ScreenTools.bottomBarHeight),
          ],
        ),
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
}

/// 标题 + 输入框/选择框的通用布局（避免重复）
class _LabeledField extends StatelessWidget {
  final String title;
  final Widget child;

  const _LabeledField({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.w,
            color: "#999999".color,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 6.w),
        child,
      ],
    );
  }
}
