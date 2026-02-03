import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../model/index.dart';
import 'package:uuid/uuid.dart';
import 'package:voicetemplate/core/index.dart';
import 'max_value_formatter.dart';
import 'package:voicetemplate/stores/global.dart';

class CreateCanvalsPage extends StatefulWidget {
  const CreateCanvalsPage({super.key});
  @override
  State<CreateCanvalsPage> createState() => _CreateCanvalsPageState();
}

class _CreateCanvalsPageState extends State<CreateCanvalsPage>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  int _selectedAspectRatio = 0;
  int _selectedClarity = 0;
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  final global = Get.find<GlobalLogic>();

  // 预设比例数据
  final List<Map<String, dynamic>> _aspectRatios = [
    {'ratio': '3:4', 'name': '竖版海报', 'width': 56.w, 'height': 73.w},
    {'ratio': '4:3', 'name': '横版海报', 'width': 59.w, 'height': 40.w},
    {'ratio': '9:16', 'name': '竖版海报', 'width': 38.w, 'height': 62.w},
    {'ratio': '16:9', 'name': '横屏海报', 'width': 56.w, 'height': 38.w},
    {'ratio': '9:21', 'name': '超长竖屏', 'width': 41.w, 'height': 62.w},
    {'ratio': '1:1', 'name': '正方形', 'width': 40.w, 'height': 40.w},
  ];

  // 预设比例数据
  final List<Map<String, dynamic>> _canvalsData = [
    {
      'ratio': '3:4',
      "isNormal": false,
      'normalW': 1200,
      'normalH': 1600,
      'hdW': 1536,
      'hdH': 2048,
    },
    {
      'ratio': '4:3',
      "isNormal": false,
      'normalW': 1600,
      'normalH': 1200,
      'hdW': 2048,
      'hdH': 1536,
    },
    {
      'ratio': '9:16',
      "isNormal": false,
      'normalW': 1080,
      'normalH': 1920,
      'hdW': 1440,
      'hdH': 2560,
    },
    {
      'ratio': '16:9',
      "isNormal": false,
      'normalW': 1920,
      'normalH': 1080,
      'hdW': 2560,
      'hdH': 1440,
    },
    {
      'ratio': '1:1',
      "isNormal": false,
      'normalW': 1080,
      'normalH': 1080,
      'hdW': 2048,
      'hdH': 2048,
    },
    {
      'ratio': '9:21',
      "isNormal": false,
      'normalW': 1080,
      'normalH': 2520,
      'hdW': 1440,
      'hdH': 3360,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
    // 重新触发高度动画
    _animationController.reset();
    _animationController.forward();
  }

  void _onCancel() {
    SmartDialog.dismiss();
  }

  void _onCreateCanvas() {
    final Uuid uuid = Uuid();
    if (_selectedTab == 0) {
      final itemModel = _aspectRatios[_selectedAspectRatio];
      final ratio = itemModel['ratio'];

      Map<String, dynamic>? result = _canvalsData.firstWhere(
        (item) => item["ratio"] == ratio,
        orElse: () => {}, // ✅ 返回 null
      );

      double width = _selectedClarity == 0
          ? result["normalW"].toDouble()
          : result["hdW"].toDouble();
      double height = _selectedClarity == 0
          ? result["normalH"].toDouble()
          : result["hdH"].toDouble();
      CanvasModel canvalsModel = CanvasModel(
        uuid: uuid.v4(),
        ratio: ratio,
        clarity: _selectedClarity == 0 ? '0' : '1',
        width: width,
        height: height,
      );

      canvalsModel.getMatrix4();
      _onCancel();
      Get.toNamed(
        AppRoutes.canvalsPage,
        arguments: {"model": canvalsModel, "type": PageSource.create},
      );
    } else {
      final int widthValue = int.tryParse(_widthController.text.trim()) ?? 0;
      final int heightValue = int.tryParse(_heightController.text.trim()) ?? 0;

      if (widthValue < 100 || heightValue < 100) {
        showToast("画布宽高不能小于100");
        return;
      }

      if (_widthController.text.isEmpty) {
        showToast("请输入宽度值");
        return;
      }
      if (_heightController.text.isEmpty) {
        showToast("请输入高度值");
        return;
      }
      double width = double.parse(_widthController.text);
      double height = double.parse(_heightController.text);
      CanvasModel canvalsModel = CanvasModel(
        uuid: uuid.v4(),
        ratio: '$width:$height',
        width: width,
        height: height,
      );
      canvalsModel.getMatrix4();
      _onCancel();
      Get.toNamed(
        AppRoutes.canvalsPage,
        arguments: {"model": canvalsModel, "type": PageSource.create},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.w),
                topRight: Radius.circular(18.w),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Container(
                  padding: EdgeInsets.only(top: 18.w),
                  child: Text(
                    '创建设计',
                    style: TextStyle(
                      fontSize: 16.w,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff262626),
                    ),
                  ),
                ),

                SizedBox(height: 22.w),

                // Tab 切换
                buildTabSelector(),

                // 内容区域
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _selectedTab == 0
                      ? buildPresetSizes()
                      : buildCustomSizes(),
                ),

                // 底部按钮
                buildBottomButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildTabSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 51.w),
      decoration: BoxDecoration(
        color: Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onTabChanged(0),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.w),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: _selectedTab == 0
                          ? [Color(0xFFC86CFF), Color(0xFF5B98FF)]
                          : [Color(0xFFA5A5A5), Color(0xFFA5A5A5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      '预设尺寸',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _onTabChanged(1),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.w),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: _selectedTab == 1
                          ? [Color(0xFFC86CFF), Color(0xFF5B98FF)]
                          : [Color(0xFFA5A5A5), Color(0xFFA5A5A5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      '自定义尺寸',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }

  Widget buildPresetSizes() {
    return Padding(
      padding: EdgeInsets.only(left: 14.w, right: 14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14.w),

          Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: Text(
              '选择画布比例',
              style: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3E3E3E),
              ),
            ),
          ),

          SizedBox(height: 12.w),

          // 比例选择网格 - 改为一行三个
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 改为2列
              childAspectRatio: 0.787, // 统一宽高比，确保所有卡片高度一致
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 13.w,
            ),
            itemCount: _aspectRatios.length,
            itemBuilder: (context, index) {
              final ratio = _aspectRatios[index];
              final isSelected = _selectedAspectRatio == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAspectRatio = index;
                  });
                },
                child: CGradientBorderWidget(
                  gradientColors: isSelected
                      ? [Color(0xFFC86CFF), Color(0xFF5B98FF)]
                      : [Color(0xFFE6E6E6), Color(0xFFE6E6E6)],
                  borderWidth: 1.0,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderRadius: BorderRadius.circular(18.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12.w),
                          child: Center(
                            child: CGradientBorderWidget(
                              gradientColors: [
                                Color(0xFFC86CFF),
                                Color(0xFF5B98FF),
                              ],
                              borderWidth: 2.0,
                              borderRadius: BorderRadius.circular(6.w),
                              child: Container(
                                width: ratio['width'].toDouble(),
                                height: ratio['height'].toDouble(),
                                color: Color(0xFF8C84FF).withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 2.w),

                      Text(
                        ratio['ratio'],
                        style: TextStyle(
                          fontSize: 16.w, // 稍微增大字体
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3E3E3E),
                        ),
                      ),

                      Text(
                        ratio['name'],
                        style: TextStyle(
                          fontSize: 12.w, // 稍微增大字体
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF3E3E3E).withValues(alpha: 0.5),
                        ),
                      ),
                      SizedBox(height: 10.w),
                    ],
                  ),
                ),
              );
            },
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: ScreenTools.screenWidth,
                padding: EdgeInsets.only(top: 14.w, left: 10.w),
                child: Text(
                  '清晰度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: "#3E3E3E".color,
                  ),
                ),
              ),
              SizedBox(height: 11.w),
              Row(
                children: [
                  buildClarityOption(0, '普通', '适合头像、资料卡\n等小尺寸图片'),
                  SizedBox(width: 14.w),
                  buildClarityOption(1, '高清', '适合背景、歌单等\n大尺寸图片'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildClarityOption(int index, String title, String description) {
    final isSelected = _selectedClarity == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClarity = index;
        });
      },
      child: CGradientBorderWidget(
        gradientColors: isSelected
            ? [Color(0xFFC86CFF), Color(0xFF5B98FF)]
            : [Color(0xFFD6D6D6), Color(0xFFD6D6D6)],
        borderWidth: 1.0,
        borderRadius: BorderRadius.circular(18.w),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        child: Container(
          width: 161.w,
          height: 95.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.w),
            color: isSelected ? Colors.white : Color(0xFFF1F1F1),
          ),
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff323232),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCustomSizes() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '自定义画布尺寸(像素)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3E3E3E),
            ),
          ),

          SizedBox(height: 13.w),

          // 输入框
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '宽度',
                      style: TextStyle(
                        fontSize: 16.w,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3E3E3E).withValues(alpha: 0.6),
                      ),
                    ),

                    SizedBox(height: 6.w),

                    TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        MaxValueFormatter(4000, 'createCanvals'),
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        hintText: '如:1080',
                        hintStyle: TextStyle(
                          color: Color(0xFF6C6C6C).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.w),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.w),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.w),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 9.w),

              Container(
                padding: EdgeInsets.only(top: 26.w),
                child: Text(
                  'X',
                  style: TextStyle(
                    fontSize: 16.w,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B8B8B),
                  ),
                ),
              ),

              SizedBox(width: 9.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '高度',
                      style: TextStyle(
                        fontSize: 16.w,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3E3E3E).withValues(alpha: 0.6),
                      ),
                    ),

                    SizedBox(height: 6.w),

                    TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        MaxValueFormatter(4000, 'createCanvals'),
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        hintText: '如:1920',
                        hintStyle: TextStyle(
                          color: Color(0xFF6C6C6C).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.w),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.w),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1.w,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.w),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1.w,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 13.w),

          // 推荐文字
          Text(
            '建议尺寸范围: 100-4000像素',
            style: TextStyle(
              fontSize: 12.w,
              color: Color(0xFF4986FF),
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 170.w),
        ],
      ),
    );
  }

  Widget buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24.w,
        26.w,
        24.w,
        ScreenTools.bottomBarHeight > 0 ? ScreenTools.bottomBarHeight : 10.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _onCancel,
              child: Image.asset(
                'assets/images/canvals/canvals_cancel_icon.png',
                width: 153.w,
                height: 40.w,
                fit: BoxFit.fill,
              ),
            ),
          ),

          SizedBox(width: 20.w),

          Expanded(
            child: GestureDetector(
              onTap: () {
                _onCreateCanvas();
              },
              child: Image.asset(
                'assets/images/canvals/canvals_sure_icon.png',
                width: 153.w,
                height: 40.w,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
