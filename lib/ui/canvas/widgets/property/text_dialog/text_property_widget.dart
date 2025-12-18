import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'model/font_info_model.dart';
import 'text_property_controller.dart';
import '../../../fonts/font_manager.dart';
import '../../../fonts/font_models.dart';

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

class _TextPropertyWidgetState extends State<TextPropertyWidget>
    with SingleTickerProviderStateMixin {
  final logic = Get.put(TextPropertyController(), tag: dialog);

  // 字体和字号
  String _fontFamily = '系统默认';
  final TextEditingController _fontSizeController = TextEditingController(
    text: '16',
  );

  // 字重
  String _fontWeight = '系统默认';
  // Tab控制器
  late TabController _tabController;

  // 字重下拉菜单显示状态
  bool _showFontWeightDropdown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFromModel();
  }

  /// 从模型初始化UI状态
  void _initializeFromModel() {
    if (widget.element == null) return;

    final data = widget.element;

    // 初始化字体ID（用于字体选择状态）
    if (data.fontId != null) {
      logic.selectedFontId.value = data.fontId;
    }

    // 初始化字体家族名（用于渲染）
    _fontFamily = data.fontFamily ?? '系统默认';

    // 初始化字号
    _fontSizeController.text = data.fontSize?.toInt().toString() ?? '16';

    // 初始化字重
    // 如果element有fontId，尝试从FontManager获取对应的FontWeightMeta来转换
    if (data.fontId != null) {
      final fontMeta = FontManager.to.allFonts[data.fontId];
      if (fontMeta != null && data.fontWeight != null) {
        // 找到最接近的FontWeightMeta
        final weightValue = data.fontWeight.value as int;
        final matchedWeight = fontMeta.weights.firstWhere(
          (w) => w.weight == weightValue,
          orElse: () {
            // 如果找不到完全匹配的，找最接近的
            FontWeightMeta? closest;
            int minDiff = 1000;
            for (final w in fontMeta.weights) {
              final diff = (w.weight - weightValue).abs();
              if (diff < minDiff) {
                minDiff = diff;
                closest = w;
              }
            }
            return closest ?? fontMeta.weights.first;
          },
        );
        _fontWeight = _weightToStyleName(matchedWeight.weight);
      } else {
        _fontWeight = _fontWeightToString(data.fontWeight);
      }
    } else {
      // 没有fontId，使用系统默认字体
      _fontWeight = _fontWeightToString(data.fontWeight);
    }
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

  /// 将字重数值转换为样式名称
  String _weightToStyleName(int weight) {
    if (weight <= 250) return 'Light';
    if (weight <= 350) return 'Light';
    if (weight <= 450) return 'Regular';
    if (weight <= 550) return 'Medium';
    if (weight <= 650) return 'Medium';
    if (weight <= 750) return 'Bold';
    if (weight <= 850) return 'Extra Bold';
    return 'Extra Bold';
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateModel({bool notify = true}) {
    final data = widget.element;

    // 更新字体ID和字体家族名
    if (logic.selectedFontId.value != null) {
      data.fontId = logic.selectedFontId.value;
    }

    // 如果选择了系统默认字体，fontId设为null
    if (_fontFamily == '系统默认') {
      data.fontId = null;
      data.fontFamily = 'Courier';
    } else {
      data.fontFamily = _fontFamily;
    }

    // 更新字号
    final fontSize = double.tryParse(_fontSizeController.text) ?? 16.0;
    data.fontSize = fontSize;

    // 更新字重
    // 如果有fontId，需要从FontManager获取对应的FontWeightMeta
    FontWeight targetWeight;
    if (logic.selectedFontId.value != null) {
      final fontMeta = FontManager.to.allFonts[logic.selectedFontId.value];
      if (fontMeta != null) {
        // 根据选择的字重字符串找到对应的FontWeightMeta
        final weightString = _fontWeight;
        FontWeightMeta? matchedWeight;
        switch (weightString) {
          case 'Light':
            matchedWeight = fontMeta.weights.firstWhere(
              (w) => w.weight <= 350,
              orElse: () => fontMeta.weights.first,
            );
            break;
          case 'Regular':
            matchedWeight = fontMeta.weights.firstWhere(
              (w) => w.weight >= 350 && w.weight <= 450,
              orElse: () =>
                  FontManager.to.getDefaultWeight(
                    logic.selectedFontId.value!,
                  ) ??
                  fontMeta.weights.first,
            );
            break;
          case 'Medium':
            matchedWeight = fontMeta.weights.firstWhere(
              (w) => w.weight >= 450 && w.weight <= 550,
              orElse: () => fontMeta.weights.first,
            );
            break;
          case 'Bold':
            matchedWeight = fontMeta.weights.firstWhere(
              (w) => w.weight >= 650 && w.weight <= 750,
              orElse: () => fontMeta.weights.first,
            );
            break;
          case 'Extra Bold':
            matchedWeight = fontMeta.weights.firstWhere(
              (w) => w.weight >= 750,
              orElse: () => fontMeta.weights.last,
            );
            break;
          default:
            matchedWeight =
                FontManager.to.getDefaultWeight(logic.selectedFontId.value!) ??
                fontMeta.weights.first;
        }
        // targetWeight = matchedWeight.flutterFontWeight;
      } else {
        // targetWeight = _stringToFontWeight(_fontWeight);
      }
    } else {
      targetWeight = _stringToFontWeight(_fontWeight);
    }

    // data.fontWeight = targetWeight;

    // 调用回调
    widget.onFontChanged(
      data.fontFamily,
      _fontSizeController.text,
      FontWeight.w700,
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
        _buildFontWeightAndSizeSection(context),
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
        // 字体列表 - 使用GetX完全响应式
        SizedBox(
          height: 211.w, // 固定高度，可根据需要调整
          child: Obx(() {
            return TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // ✅ 禁止拖动
              children: [
                // 推荐字体 Tab - 完全响应式
                _buildFontList(logic.recommendedFonts),
                // 全部字体 Tab - 完全响应式
                _buildFontList(logic.allFonts),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// 构建字体列表（每行3个）- 使用GetX响应式
  Widget _buildFontList(List<FontInfoModel> fonts) {
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
          // 使用GetX响应式判断是否选中
          return Obx(() {
            final selectedId = logic.selectedFontId.value;
            final isSelected = selectedId != null && selectedId == font.id;
            return _buildFontItem(font, isSelected);
          });
        },
      ),
    );
  }

  /// 构建单个字体项
  Widget _buildFontItem(FontInfoModel font, bool isSelected) {
    // 使用 Obx 监听字体状态变化
    return Obx(() {
      final fontStatus =
          FontManager.to.fontStatus[font.id] ?? FontStatus.missing;
      final isReady = fontStatus == FontStatus.ready;
      final isDownloading = fontStatus == FontStatus.downloading;
      final isInstalling = fontStatus == FontStatus.installing;
      final isFailed = fontStatus == FontStatus.failed;
      // 获取字体元数据（如果已安装）
      final fontMeta = FontManager.to.allFonts[font.id];

      return Column(
        children: [
          // 字体预览按钮
          Expanded(
            child: GestureDetector(
              onTap: () async {
                // 如果字体已准备好，直接选中
                if (isReady && fontMeta != null) {
                  // 使用GetX更新选中状态
                  logic.selectedFontId.value = font.id;
                  setState(() {
                    _fontFamily = fontMeta.familyKey;
                    // 获取默认字重
                    final defaultWeight = FontManager.to.getDefaultWeight(
                      font.id,
                    );
                    if (defaultWeight != null) {
                      _fontWeight = _weightToStyleName(defaultWeight.weight);
                    }
                    _updateModel();
                  });
                  return;
                }

                // 如果正在下载或安装中，不重复触发
                if (isDownloading || isInstalling) {
                  return;
                }

                // 如果字体未准备好，调用 FontManager 准备字体
                try {
                  final meta = await FontManager.to.prepareFontByInfo(
                    font,
                    onProgress: (progress) {
                      // 可以在这里显示进度，如果需要的话
                      debugPrint(
                        '字体 ${font.name} 下载进度: ${(progress * 100).toStringAsFixed(1)}%',
                      );
                    },
                  );
                  // 字体准备成功后，更新选中状态
                  if (mounted) {
                    // 使用GetX更新选中状态
                    logic.selectedFontId.value = font.id;
                    setState(() {
                      _fontFamily = meta.familyKey;
                      // 获取默认字重
                      final defaultWeight = FontManager.to.getDefaultWeight(
                        font.id,
                      );
                      if (defaultWeight != null) {
                        _fontWeight = _weightToStyleName(defaultWeight.weight);
                      }
                      _updateModel();
                    });
                  }
                } catch (e) {
                  debugPrint('字体准备失败: $e');
                  // 可以显示错误提示
                  if (mounted) {
                    // 可以在这里显示 Toast 提示用户
                    // SmartDialog.showToast('字体下载失败，请重试');
                  }
                }
              },
              child: SelectItemGradientBorder(
                isSelected: isSelected && isReady,
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
                    Positioned.fill(child: _buildFontPreviewImage(font.image)),

                    // 下载/安装中的加载指示器
                    if (isDownloading || isInstalling)
                      Center(
                        child: SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CAssetImage(
                            imgUrl:
                                'assets/images/canvals/text_property_loading.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    // 下载图标（如果字体未安装且不在下载/安装中）
                    if (!isReady &&
                        !isDownloading &&
                        !isInstalling &&
                        !isFailed)
                      Positioned(
                        top: 2.w,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CAssetImage(
                              imgUrl:
                                  'assets/images/canvals/text_property_download.png',
                              fit: BoxFit.cover,
                            ),
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
            style: TextStyle(
              fontSize: 12.w,
              color: "#232535".color,
              // 如果字体已准备好，可以加粗显示
              fontWeight: isReady ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    });
  }

  /// 构建字体预览图片（修复URI错误）
  Widget _buildFontPreviewImage(String imageUrl) {
    // 验证URL是否有效
    if (imageUrl.isEmpty) {
      return CAssetImage(
        imgUrl: 'assets/images/canvals/text_property_download.png',
        fit: BoxFit.cover,
      );
    }

    // 检查URL格式
    final isValidUrl =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('assets/');

    if (!isValidUrl) {
      // 如果URL格式无效，使用占位图
      return CAssetImage(
        imgUrl: 'assets/images/canvals/text_property_download.png',
        fit: BoxFit.cover,
      );
    }

    // 如果是网络图片，使用CachedNetworkImage
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => CAssetImage(
          imgUrl: 'assets/images/canvals/text_property_download.png',
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) {
          // 修复URI错误：当图片加载失败时显示占位图
          debugPrint('字体预览图片加载失败: $url, 错误: $error');
          return CAssetImage(
            imgUrl: 'assets/images/canvals/text_property_download.png',
            fit: BoxFit.cover,
          );
        },
      );
    }

    // 如果是本地资源，使用CAssetImage
    return CAssetImage(imgUrl: imageUrl, fit: BoxFit.cover);
  }

  /// 构建字重和字号区域
  /// 构建字重和字号区域（修复：Row 内无限宽/约束问题）
  Widget _buildFontWeightAndSizeSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      title: '字重',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.w),
                        onTap: () {
                          // 先收起键盘
                          FocusManager.instance.primaryFocus?.unfocus();
                          logic.getCurrentFontIdWeight();
                          setState(() {
                            _showFontWeightDropdown = !_showFontWeightDropdown;
                          });
                        },
                        child: Container(
                          height: 42.w,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.w),
                            border: Border.all(
                              color: "#FFE6E6E6".color,
                              width: 1.w,
                            ),
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
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: Image.asset(
                                  'assets/images/canvals/canvals_text_font_down.png',
                                  fit: BoxFit.cover,
                                ),
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
                          border: Border.all(
                            color: "#ffE6E6E6".color,
                            width: 1.w,
                          ),
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
                          onTap: () {
                            // 点击字号输入框时关闭字重下拉菜单
                            if (_showFontWeightDropdown) {
                              setState(() {
                                _showFontWeightDropdown = false;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_showFontWeightDropdown) SizedBox(height: 80.w),
              if (!_showFontWeightDropdown) SizedBox(height: 20.w),
              // 删除文本按钮
              _buildDeleteButton(),
              SizedBox(height: ScreenTools.bottomBarHeight + 15.w),
            ],
          ),

          // 字重下拉菜单
          if (_showFontWeightDropdown)
            Positioned(
              left: 11.w,
              top: 42.w + 15.w,
              child: Container(
                width: 125.w,
                height: 154.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.w),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCDE4FF), // 外阴影颜色
                      offset: const Offset(0, 1), // Offset X=0, Y=1
                      blurRadius: 5, // Effect blur=5
                      spreadRadius: 0, // Effect spread=0
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 7.w,
                  right: 10.w,
                  top: 10.w,
                  bottom: 5.w,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: logic.fontWeights.map((weight) {
                      final isSelected = _fontWeight == weight;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _fontWeight = weight;
                            _showFontWeightDropdown = false;
                            _updateModel();
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? "#DCEDFE".color.withValues(alpha: 0.6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Text(
                            weight,
                            style: TextStyle(
                              fontSize: 14.w,
                              color: isSelected
                                  ? "#3C7BFF".color
                                  : "#242424".color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
