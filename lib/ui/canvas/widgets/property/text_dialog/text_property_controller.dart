import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'model/font_info_model.dart';

const String dialog = 'TextPropertyDialogController';

/// 文本属性（字体相关）控制器
///
/// 负责管理：
/// - 当前字体 family / size / weight
/// - 推荐字体 / 全部字体列表
/// - 将变更回写到画布元素（element）
class TextPropertyController extends GetxController {
  /// 画布上的文本元素（原来从 TextPropertyWidget / Dialog 传入的 element）
  // final dynamic element;

  /// 外部传入的字体列表（一般为接口数据）
  final List<FontInfoModel> fontList = [];

  /// 当前选中的字体 family
  final RxString fontFamily = '系统默认'.obs;

  /// 当前字号（字符串形式，方便直接绑定到输入框）
  final RxString fontSize = '16'.obs;

  /// 当前字重（以字符串描述：Light / Regular / Bold 等）
  final RxString fontWeight = '系统默认'.obs;

  // TextPropertyController({required this.element});

  @override
  void onInit() {
    super.onInit();
    debugPrint("-获取字体列表中数据----onInit------");
    getFontListData();
    // _initFromElement();
  }

  ///1、获取字体列表中数据
  void getFontListData() async {
    final result = await http.post(
      '/front/index',
      withToken: true,
      showErrorToast: true,
      converter: listConverter(FontInfoModel.fromJson),
    );

    debugPrint("-获取字体列表中数据----getFontListData---${result.data}---");
  }

  /// 从 element 初始化当前 UI 状态
  // void _initFromElement() {
  //   if (element == null) return;

  //   try {
  //     fontFamily.value = element.fontFamily ?? '系统默认';
  //   } catch (_) {}

  //   try {
  //     final size = element.fontSize;
  //     fontSize.value =
  //         (size is num ? size.toDouble() : double.tryParse('$size') ?? 16)
  //             .toInt()
  //             .toString();
  //   } catch (_) {}

  //   try {
  //     fontWeight.value = _fontWeightToString(element.fontWeight);
  //   } catch (_) {}
  // }

  /// 内部：FontWeight -> 文本
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

  /// 内部：文本 -> FontWeight
  FontWeight _stringToFontWeight(String value) {
    switch (value) {
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

  /// 选中某个字体
  // void selectFont(FontItem font) {
  //   fontFamily.value = font.fontFamily;
  //   _applyToElement();
  // }

  /// 更新字号
  void updateFontSize(String value) {
    if (value.isEmpty) return;
    fontSize.value = value;
    _applyToElement();
  }

  /// 更新字重
  void updateFontWeight(String value) {
    fontWeight.value = value;
    _applyToElement();
  }

  /// 将当前 controller 状态写回到 element（不触发外部回调，由外部决定何时通知）
  void _applyToElement() {
    // if (element == null) return;
    // try {
    //   element.fontFamily = fontFamily.value == '系统默认'
    //       ? 'Courier'
    //       : fontFamily.value;
    // } catch (_) {}

    // try {
    //   element.fontSize = double.tryParse(fontSize.value) ?? 16.0;
    // } catch (_) {}

    // try {
    //   element.fontWeight = _stringToFontWeight(fontWeight.value);
    // } catch (_) {}
  }

  @override
  void onClose() {
    debugPrint("-获取字体列表中数据----onClose------");
    super.onClose();
  }
}
