import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../canvals_file_manager.dart';
import 'dart:io';
import 'dart:ui' as ui;

/// 图片处理结果
class ImageProcessResult {
  final String? imagePath;
  final double width;
  final double height;
  final bool success;

  ImageProcessResult({
    this.imagePath,
    required this.width,
    required this.height,
    required this.success,
  });
}

class ImageStorageManager {
  static const int maxSizeInMB = 10;

  // 只从相册获取数据
  static void chooseImages({
    required BuildContext context,
    required String canvalsID,
    required void Function(String imagePath, double width, double height)
    onSuccess,
  }) async {
    try {
      final List<AssetEntity>? result = await ImageStorageManager.common(
        context,
      );
      if (result != null) {
        final targetPath = await CanvalsFileManager.getImagePath(canvalsID);
        final processResult = await ImageStorageManager.checkFileSize(
          result.last,
          targetPath,
        );
        if (processResult.success && processResult.imagePath != null) {
          onSuccess(
            processResult.imagePath!,
            processResult.width,
            processResult.height,
          );
        } else {
          showToast('图片处理失败，请重试');
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

  /// 检查并处理图片大小
  /// [asset] 图片资源
  /// [targetPath] 目标保存路径
  /// 返回处理结果，包含图片路径和宽高
  static Future<ImageProcessResult> checkFileSize(
    AssetEntity asset,
    String targetPath,
  ) async {
    // 加载原始文件
    final File? originFile = await asset.loadFile(isOrigin: true);
    if (originFile == null) {
      // 加载失败
      return ImageProcessResult(
        width: asset.width.toDouble(),
        height: asset.height.toDouble(),
        success: false,
      );
    }

    File? finalFile;

    // 如果本身就没超过 10MB，直接复制到目标路径
    if (!isOverLimit(originFile)) {
      finalFile = await originFile.copy(targetPath);
    } else {
      // 已经超过 10MB，尝试不断压缩到 10MB 以内
      int quality = 90; // 初始压缩质量
      const int minQuality = 20; // 最低可接受质量
      File currentFile = originFile;

      while (isOverLimit(currentFile) && quality >= minQuality) {
        final compressed = await FlutterImageCompress.compressAndGetFile(
          currentFile.absolute.path,
          targetPath, // 压缩到目标路径
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (compressed == null) {
          break;
        }

        finalFile = File(compressed.path);

        // 如果压缩后文件大小满足要求，退出循环
        if (!isOverLimit(finalFile)) {
          break;
        }

        // 如果还没满足要求，继续压缩（使用压缩后的文件作为下一次的输入）
        currentFile = finalFile;
        quality -= 10;
      }
    }

    // 如果最终文件仍然超出限制或处理失败，返回失败结果
    if (finalFile == null || isOverLimit(finalFile)) {
      return ImageProcessResult(
        width: asset.width.toDouble(),
        height: asset.height.toDouble(),
        success: false,
      );
    }

    // 读取最终文件的宽高
    final size = await _getImageSizeFromFile(finalFile);
    final double width = size?.width ?? asset.width.toDouble();
    final double height = size?.height ?? asset.height.toDouble();

    return ImageProcessResult(
      imagePath: finalFile.path,
      width: width,
      height: height,
      success: true,
    );
  }

  // 工具：计算是否超过限制
  static bool isOverLimit(File file) {
    final int lengthInBytes = file.lengthSync();
    final double lengthInMB = lengthInBytes / (1024 * 1024);
    return lengthInMB > maxSizeInMB;
  }

  /// 从文件读取图片的宽高（像素）
  static Future<Size?> _getImageSizeFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e, stackTrace) {
      debugPrint('读取图片尺寸失败: $e ----- $stackTrace');
      return null;
    }
  }
}
