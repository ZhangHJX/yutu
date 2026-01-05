import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'model/font_info_model.dart';
import '../../../fonts/font_manager.dart';
import 'package:voicetemplate/ui/canvas/fonts/font_models.dart';

/// 文本属性（字体相关）控制器
class TextPropertyController extends GetxController {
  /// 全部字体列表（从接口获取的数据）
  final RxList<FontInfoModel> fontList = <FontInfoModel>[].obs;
  List<FontInfoModel> get allFontList => fontList.toList();

  //获取推荐字体列表（从 FontManager 获取，并转换为 FontInfoModel）
  final RxList<FontInfoModel> recommendedFonts = <FontInfoModel>[].obs;
  List<FontInfoModel> get allRecommendedFonts => recommendedFonts.toList();

  /// 字体相关属性
  final RxString familyKey = 'AlibabaPuHuiTi'.obs;
  final RxString styleName = defaultConfigStyleName.obs;
  final RxString version = '1.0.0'.obs;
  final RxnInt selectedFontId = RxnInt();
  final RxString fontSize = '16'.obs;

  Worker? _countWorker;

  // 字重列表
  List<String> fontWeights = [];
  RxBool get isFontEdit => FontManager.to.isInstallingTasks.obs;

  @override
  void onInit() {
    super.onInit();
    getFontListData();
    _countWorker = ever(FontManager.to.recommendedFonts, (value) {
      final recommendedList = <FontInfoModel>[];
      final fontMap = {for (var font in fontList) font.id: font};
      // 按照推荐顺序添加
      for (final meta in value) {
        final font = fontMap[meta.fontId];
        if (font != null) {
          recommendedList.add(font);
        }
      }
      recommendedFonts.value = recommendedList;
    });
  }

  /// 获取字体列表pop数据
  void getCurrentFontIdWeight() {
    final weightList = FontManager.to.getWeights(selectedFontId.value ?? 1);
    weightList.sort((FontWeightMeta a, FontWeightMeta b) {
      return a.weight.compareTo(b.weight);
    });
    fontWeights = weightList.map((FontWeightMeta meta) {
      return meta.styleName;
    }).toList();
  }

  /// 获取字体列表中数据
  Future<void> getFontListData() async {
    try {
      final result = await http.post(
        '/front/index',
        showErrorToast: false,
        converter: listConverter(FontInfoModel.fromJson),
      );
      if (result.code == 0 && result.data != null) {
        // 更新字体列表
        final modelArray = result.data as List<FontInfoModel>;
        fontList.assignAll(modelArray);
        // 将字体 ID 列表传递给 FontManager，用于推荐字体
        // final fontIds = fontList.map((f) => f.id).toList();
        // FontManager.to.setTemplateUsedFonts(fontIds);
        debugPrint("-获取字体列表中数据成功--数量: ${fontList.length}");
        await FontManager.to.warmUpdateInstalledFonts(modelArray);
      }
    } catch (e) {
      debugPrint("-获取字体列表中数据异常: $e");
    }
  }

  @override
  void onClose() {
    _countWorker?.dispose();
    debugPrint("-获取字体列表中数据----onClose------");
    super.onClose();
  }
}
