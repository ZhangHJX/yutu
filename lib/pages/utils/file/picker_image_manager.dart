import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:voicetemplate/file/index.dart';
import 'image_camera_utils.dart';

class PickerImageManager {
  static const int maxSizeBites = 10 * 1024 * 1024;

  static late String cavalsPath;

  static Future<void> init() async {
    final cavals = await DirectoryManager.getDocumentsSubDirectory(
      'cavals/images',
    );
    cavalsPath = cavals.path;
  }

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

  /// 加载画布中的图片
  static String loadCanvalsImage(String imagePath) {
    return p.join(cavalsPath, imagePath);
  }
}
