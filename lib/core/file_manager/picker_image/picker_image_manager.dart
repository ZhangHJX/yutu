import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/core/index.dart';

class PickerImageManager {
  // 最大允许的图片大小（字节），当前为 10MB
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
    required void Function(List<PickerInfoModel> infoModel) onSuccess,
    int maxCount = 1,
  }) async {
    try {
      final List<AssetEntity>? assetArray = await PickerImageManager.common(
        context,
        maxAssetsCount: maxCount,
      );
      if (assetArray != null && assetArray.isNotEmpty) {
        final List<PickerInfoModel> imgArray = [];
        for (var i = 0; i < assetArray.length; i++) {
          AssetEntity asset = assetArray[i];
          final result = await ImageHandleUtils.getAssetImageFilePath(asset);
          if (result.$1.isEmpty) continue;
          int fileSize = await ImageHandleUtils.getAssetFileSize(asset);

          final int fileSizeKb = (fileSize / 1024).ceil();

          PickerInfoModel model = PickerInfoModel(
            filePath: result.$1,
            width: asset.width.toDouble(),
            height: asset.height.toDouble(),
            fileSize: fileSizeKb,
            hashValue: result.$2,
          );
          if (fileSize > maxSizeBites) {
            final imgInfo = await ImageHandleUtils.getCompressFilePath(
              result.$1,
              fileSize,
              asset,
            );
            final int compressKb = (imgInfo.$4 / 1024).ceil();
            model.filePath = imgInfo.$1;
            model.width = imgInfo.$2;
            model.height = imgInfo.$3;
            model.fileSize = compressKb;
          }
          imgArray.add(model);
        }
        onSuccess(imgArray);
      }
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      AppLogger.error('读取照片路径报错，请重试:', e, stackTrace);
    }
  }

  // 公共的选择方法
  static Future<List<AssetEntity>?> common(
    BuildContext context, {
    int maxAssetsCount = 9,
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
