import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SelectSourceTools {
  // 只从相册获取数据
  static void chooseImages({
    required BuildContext context,
    required void Function(AssetEntity assetEntity) onSuccess,
  }) async {
    try {
      final List<AssetEntity>? result = await SelectSourceTools.common(context);
      if (result != null) {
        onSuccess(result.last);
      }
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      debugPrint('读取照片路径报错，请重试: $e-----$stackTrace');
    }
  }

  // 公共的选择方法
  static Future<List<AssetEntity>?> common(
    BuildContext context, {
    int maxAssetsCount = 1,
  }) async {
    return AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxAssetsCount,
        requestType: RequestType.image,
        textDelegate: const AssetPickerTextDelegate(),
      ),
    );
  }
}

// https://blog.csdn.net/qq_40745143/article/details/149416600
