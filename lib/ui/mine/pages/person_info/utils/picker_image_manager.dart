import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'image_camera_utils.dart';
import 'dart:io';

class PickerImageManager {
  static const int maxSizeBites = 10 * 1024 * 1024;

  // 只从相册获取数据
  static void pickerPhotos({
    required BuildContext context,
    required void Function(
      String fiePath,
      double width,
      double height,
      int fileSize,
    )
    onSuccess,
  }) async {
    try {
      final List<AssetEntity>? result = await PickerImageManager.common(
        context,
      );
      if (result != null) {
        AssetEntity asset = result.last;
        String filePath = await ImageCameraUtils.getAssetImageFilePath(asset);
        int fileSize = await ImageCameraUtils.getAssetFileSize(asset);
        if (fileSize > maxSizeBites) {
          final imgInfo = await ImageCameraUtils.getCompressFilePath(
            filePath,
            fileSize,
            asset,
          );
          onSuccess(imgInfo.$1, imgInfo.$2, imgInfo.$3, imgInfo.$4);
        } else {
          onSuccess(
            filePath,
            asset.width.toDouble(),
            asset.height.toDouble(),
            fileSize,
          );
        }
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

  /// 删除临时目录下的图片
  static void deleteTempFile(String filePath) async {
    if (filePath.isEmpty) {
      return;
    }
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }
    await file.delete();
  }
}
