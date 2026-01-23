import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'model/font_info_model.dart';
import '../../../fonts/font_manager.dart';
import 'package:voicetemplate/pages/canvas/fonts/font_models.dart';
import '../../../pages/canvals/canvals_controller.dart';

/// 文本属性（字体相关）控制器
class TextPropertyController extends GetxController {
  final canvalsControl = Get.find<CanvalsController>();

  /// 全部字体列表（从接口获取的数据）
  final RxList<FontInfoModel> fontList = <FontInfoModel>[].obs;
  List<FontInfoModel> get allFontList => fontList.toList();

  //获取推荐字体列表（从 FontManager 获取，并转换为 FontInfoModel）
  final RxList<FontInfoModel> recommendedFonts = <FontInfoModel>[].obs;
  List<FontInfoModel> get allRecommendedFonts => recommendedFonts.toList();

  /// 字体相关属性
  final RxString familyKey = 'AlibabaPuHuiTi'.obs;
  final RxString styleName = defaultConfigStyleName.obs;
  final RxnInt selectedFontId = RxnInt();
  final RxString fontSize = '16'.obs;

  Worker? _countWorker;

  // 字重列表
  List<String> fontWeights = [];

  // 字重下拉菜单显示状态
  RxBool showFontWeightDropdown = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentUseFonts();
    getFontListData();
    _countWorker = ever(FontManager.to.recommendedFonts, (value) {
      final tempFonts = FontManager.to.recommendedFonts.map((meta) {
        final m = FontInfoModel(
          id: meta.fontId,
          version: meta.version,
          name: meta.fontName,
          image: meta.fontImage,
          url: meta.downloadUrl,
        );
        return m;
      });
      recommendedFonts.assignAll(tempFonts);
    });
  }

  /// 获取已使用的字体
  void currentUseFonts() {
    debugPrint("-获取字体列表中数据----${FontManager.to.recommendedFonts.length}------");

    if (FontManager.to.recommendedFonts.isEmpty) {
      final canvasModel = canvalsControl.buildSnapshot();
      if (canvasModel != null) {
        final fontIds = canvasModel.elements
            .map((e) => e.fontId)
            .where((id) => id > 0)
            .toList();
        FontManager.to.markUsedFonts(fontIds);
      }
    } else {
      final tempFonts = FontManager.to.recommendedFonts.map((meta) {
        final m = FontInfoModel(
          id: meta.fontId,
          version: meta.version,
          name: meta.fontName,
          image: meta.fontImage,
          url: meta.downloadUrl,
        );
        return m;
      });
      recommendedFonts.assignAll(tempFonts);
    }
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
        converter: listConverter(FontInfoModel.fromJson),
      );
      if (result.code == 0 && result.data != null) {
        // 更新字体列表
        final modelArray = result.data as List<FontInfoModel>;
        fontList.assignAll(modelArray);
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
