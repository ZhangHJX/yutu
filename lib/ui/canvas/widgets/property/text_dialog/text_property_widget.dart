import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/ui/canvas/widgets/property/text_dialog/widgets/spinning_widget.dart';
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
  final Function(String, double, String, int) onFontChanged;

  const TextPropertyWidget({
    super.key,
    required this.element,
    this.onPropertyChanged,
    this.onDeleteText,
    required this.onFontChanged,
  });

  @override
  State<TextPropertyWidget> createState() => _TextPropertyWidgetState();
}

class _TextPropertyWidgetState extends State<TextPropertyWidget>
    with SingleTickerProviderStateMixin {
  final logic = Get.put(TextPropertyController(), tag: fontDialog);

  final TextEditingController _fontSizeController = TextEditingController();
  // Tab控制器
  late TabController _tabController;

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
    logic.selectedFontId.value = data.fontId;
    logic.styleName.value = data.styleName;
    logic.familyKey.value = data.familyKey;
    logic.selectedFontId.value = data.fontId;
    // 初始化字号
    _fontSizeController.text = data.fontSize?.toInt().toString() ?? '14';
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateModel({bool notify = true}) {
    // 更新字号 - 保持为 double 类型以匹配 CanvasElement.fontSize
    final fontSize = double.tryParse(_fontSizeController.text) ?? 16.0;
    // 调用回调
    widget.onFontChanged(
      logic.familyKey.value, // ✅ 使用找到的 familyKey
      fontSize,
      logic.styleName.value, // ✅ 使用找到的 styleName
      logic.selectedFontId.value ?? 0,
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
                _buildFontList(logic.allRecommendedFonts),
                // 全部字体 Tab - 完全响应式
                _buildFontList(logic.allFontList),
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
                if (logic.selectedFontId.value == font.id) {
                  return;
                }
                if (FontManager.to.isInstallingTasks) {
                  showToast("已有字体在下载，请稍后操作");
                  return;
                }

                if (logic.showFontWeightDropdown.value) {
                  logic.showFontWeightDropdown.value = false;
                }
                // 如果字体已准备好，直接选中
                if (isReady && fontMeta != null) {
                  // 使用GetX更新选中状态
                  logic.selectedFontId.value = font.id;
                  final meta = FontManager.to.allFonts[font.id];
                  if (meta != null && meta.weights.isNotEmpty) {
                    logic.familyKey.value = meta.weights.first.familyKey;
                    logic.styleName.value = meta.weights.first.styleName;
                  }
                  FontManager.to.markUsed(font.id);
                  setState(() {
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
                      debugPrint('字体 ${font.name} 下载进度: $progress');
                    },
                  );

                  FontManager.to.markUsed(font.id);
                  // 字体准备成功后，更新选中状态
                  if (mounted) {
                    logic.selectedFontId.value = font.id;
                    logic.familyKey.value = meta.weights.first.familyKey;
                    logic.styleName.value = meta.weights.first.styleName;
                    setState(() {
                      _updateModel();
                    });
                  }
                } catch (e) {
                  FontManager.to.fontStatus[font.id] == FontStatus.failed;
                  debugPrint('字体准备失败: $e');
                  showToast('字体下载失败，请重试');
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
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: font.image,
                        imageBuilder: (context, imageProvider) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.w),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.w),
                            color: const Color(0xFFE7EEF7),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.w),
                            color: const Color(0xFFE7EEF7),
                          ),
                        ),
                        fadeInDuration: const Duration(milliseconds: 200),
                      ),
                    ),

                    // 下载/安装中的加载指示器
                    if (isDownloading || isInstalling)
                      Center(
                        child: SpinningWidget(
                          child: CAssetImage(
                            imgUrl:
                                'assets/images/canvals/text_property_loading.png',
                            fit: BoxFit.cover,
                            size: 16.w,
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

  /// 构建字重和字号区域 修复：Row 内无限宽/约束问题）
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
                          if (FontManager.to.isInstallingTasks) {
                            showToast("字体正在下载中，暂不能操作");
                            return;
                          }
                          // 先收起键盘
                          FocusManager.instance.primaryFocus?.unfocus();
                          logic.getCurrentFontIdWeight();
                          setState(() {
                            logic.showFontWeightDropdown.value =
                                !logic.showFontWeightDropdown.value;
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
                                  logic.styleName.value,
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
                        child: Obx(() {
                          return TextField(
                            controller: _fontSizeController,
                            keyboardType: TextInputType.number,
                            enabled: !logic.showFontWeightDropdown.value,
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
                              if (logic.showFontWeightDropdown.value) {
                                setState(() {
                                  logic.showFontWeightDropdown.value = false;
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
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),

              if (logic.showFontWeightDropdown.value) SizedBox(height: 80.w),
              if (!logic.showFontWeightDropdown.value) SizedBox(height: 20.w),
              // 删除文本按钮
              _buildDeleteButton(),
              SizedBox(height: ScreenTools.bottomBarHeight + 15.w),
            ],
          ),

          // 字重下拉菜单
          if (logic.showFontWeightDropdown.value)
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
                    children: logic.fontWeights.map((value) {
                      final isSelected = logic.styleName.value == value;
                      return InkWell(
                        onTap: () {
                          final meta = FontManager
                              .to
                              .allFonts[logic.selectedFontId.value];
                          if (meta != null) {
                            final weight = meta.weights
                                .where((u) => u.styleName == value)
                                .firstOrNull;
                            logic.familyKey.value = weight?.familyKey ?? '';
                          }
                          logic.styleName.value = value;
                          setState(() {
                            logic.showFontWeightDropdown.value = false;
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
                            value,
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
