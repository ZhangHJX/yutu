import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'dart:io';

class PickerImageManager {
  static const int maxSizeInMB = 10 * 1024 * 1024;

  // 只从相册获取数据
  static void pickerPhotos({
    required BuildContext context,
    required void Function(String fiePath, double width, double height)
    onSuccess,
  }) async {
    try {
      final List<AssetEntity>? result = await PickerImageManager.common(
        context,
      );
      if (result != null) {
        AssetEntity asset = result.last;
        String filePath = await PickerImageManager.getAssetImageFilePath(asset);
        onSuccess(filePath, asset.width.toDouble(), asset.height.toDouble());
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

  static Future<String> getAssetImageFilePath(AssetEntity asset) async {
    try {
      // 优先拿原图
      File? originalFile = await asset.originFile;

      /// 有些情况下 originFile 为 null，可以尝试 file
      originalFile ??= await asset.file;

      if (originalFile == null) {
        debugPrint('getAssetImageFilePath: 无法获取本地文件, asset id = ${asset.id}');
        return "";
      }
      return originalFile.path;
    } catch (error, stackTrace) {
      debugPrint('getAssetImageFilePath: 异常 = $error == $stackTrace');
      return "";
    }
  }
}
