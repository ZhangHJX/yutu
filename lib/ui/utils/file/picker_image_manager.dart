import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:voicetemplate/file/index.dart';
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
      debugPrint('PickerImageManager---$result--');
      if (result != null) {
        AssetEntity asset = result.last;
        String filePath = await ImageCameraUtils.getAssetImageFilePath(asset);
        if (filePath.isEmpty) {
          showToast("未选到图片，请重试");
          return;
        }
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

  /// 删除在相册中选中的图片的临时保存路径
  static Future<void> deleteDirectory() async {
    final tempDir = await DirectoryManager.getTempSubDirectory("images");
    await FileManager.deleteDirectory(tempDir);
  }

  /// 我的素材的绝对路径
  static Future<Directory> getSuCaiRelative() async {
    return await DirectoryManager.getDocumentsSubDirectory('localAsset');
  }

  /// 我的草稿的绝对路径
  static Future<Directory> getCaoGaoRelative() async {
    return await DirectoryManager.getDocumentsSubDirectory('caval/images');
  }

  // 从模型的相对路径拿到可用的绝对路径
  static Future<String> getImageFromRelative(
    Directory directory,
    String imagePath,
  ) async {
    return p.join(directory.path, imagePath);
  }
}
