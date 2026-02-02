import 'dart:typed_data' as typed_data;
import 'dart:typed_data';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:voicetemplate/core/file_manager/directory_path/index.dart';
import 'package:path/path.dart' as p;
import 'transform_tools.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:common/common.dart';

class ImageCameraUtils {
  static const int maxSizeInMB = 10 * 1024 * 1024;

  ///1、获取文件后缀名
  static String getFileExtensionFromPath(String filePath) {
    if (filePath.isEmpty) {
      return '';
    }
    final String extensionWithDot = p.extension(
      filePath,
    ); // 如 ".png" / ".heic" / ""
    if (extensionWithDot.isEmpty) {
      return '';
    }
    final String extension = extensionWithDot.startsWith('.')
        ? extensionWithDot.substring(1)
        : extensionWithDot;

    return extension.toLowerCase();
  }

  ///2、获取相册图片的路径
  static Future<String> getAssetImageFilePath(AssetEntity asset) async {
    // 优先拿原图
    File? originalFile = await asset.originFile;

    /// 有些情况下 originFile 为 null，可以尝试 file
    originalFile ??= await asset.file;
    if (originalFile == null) {
      return "";
    }

    final fileName = p.basenameWithoutExtension(originalFile.path);
    final ext = getFileExtensionFromPath(originalFile.path);
    final tempDir = await DirectoryManager.getTempSubDirectory("images");

    if (ext == 'gif') {
      final Uint8List? origin = await asset.originBytes; // 可能为 null
      final fullPath = p.join(tempDir.path, '$fileName.png');
      if (origin != null && origin.isNotEmpty) {
        final bytes = await TransformTools.gifToPngFrame(origin);
        final file = File(fullPath);
        if (bytes != null && bytes.isNotEmpty) {
          await file.writeAsBytes(bytes, flush: true);
        }
        return file.path;
      }
      return '';
    } else {
      AppLogger.info('进入到图片类型的分支中');
      final fullPath = p.join(tempDir.path, '$fileName.$ext');
      //copy到新的路径下
      await originalFile.copy(fullPath);
      return fullPath;
    }
  }

  ///3、获取 AssetEntity 对应文件的大小（单位：byte）
  static Future<int> getAssetFileSize(AssetEntity asset) async {
    try {
      // 优先原图
      File? file = await asset.originFile;
      // 有些情况 originFile 为 null，可以尝试 file
      file ??= await asset.file;

      if (file == null) {
        AppLogger.info('getAssetFileSize: 文件为 null, asset id = ${asset.id}');
        return 0;
      }
      final int length = await file.length(); // 单位：byte
      final kbCeil = (length / 1024).ceil(); // 向上取整

      AppLogger.info('getAssetFileSize: 文件为 null, asset id = ${asset.id}');

      return kbCeil;
    } catch (e, s) {
      AppLogger.error('getAssetFileSize: 异常:', e, s);
      return 0;
    }
  }

  ///4、压缩图片文件
  static Future<(String filePath, double width, double height, int size)>
  getCompressFilePath(String filePath, int fileSize, AssetEntity asset) async {
    try {
      final fileName = p.basenameWithoutExtension(filePath);
      final ext = getFileExtensionFromPath(filePath);
      final tempDir = await DirectoryManager.getTempSubDirectory("images");
      final compressedPath = p.join(tempDir.path, '${fileName}_compressed$ext');

      // 根据文件扩展名选择压缩格式
      CompressFormat format = CompressFormat.jpeg;
      if (ext == '.png') {
        format = CompressFormat.png;
      } else if (ext == '.webp') {
        format = CompressFormat.webp;
      } else if (ext == '.heic') {
        format = CompressFormat.heic;
      }

      int quality = 90; // 初始压缩质量
      int minQuality = 20; // 最低可接受质量
      int imgeSize = fileSize;

      typed_data.Uint8List compressedBytes = typed_data.Uint8List(0);

      // 压缩图片
      while (imgeSize > maxSizeInMB && quality >= minQuality) {
        compressedBytes = await compressFile(
          filePath,
          format,
          quality,
          minQuality,
          minQuality,
        );
        imgeSize = compressedBytes.length;
        if (imgeSize > maxSizeInMB) {
          compressedBytes.clear();
        }
        quality -= 10;
      }

      if (compressedBytes.isNotEmpty) {
        // 将压缩后的数据写入临时文件
        final compressedFile = File(compressedPath);
        await compressedFile.writeAsBytes(compressedBytes);
        final imgInfo = await getImageSizeFromBytes(compressedBytes, asset);
        return (compressedPath, imgInfo.$1, imgInfo.$2, imgeSize.bitLength);
      } else {
        // 压缩失败，返回原文件路径
        AppLogger.info('🤯🤯🤯图片压缩失败，使用原文件: $filePath');
        return (
          filePath,
          asset.width.toDouble(),
          asset.height.toDouble(),
          imgeSize.bitLength,
        );
      }
    } catch (e) {
      AppLogger.error('图片压缩出错 使用原文件: $filePath', e);
      return (
        filePath,
        asset.width.toDouble(),
        asset.height.toDouble(),
        fileSize,
      );
    }
  }

  ///5、压缩方法递归计算
  static Future<typed_data.Uint8List> compressFile(
    String filePath,
    CompressFormat format,
    int quality,
    int minQuality,
    int minWidth,
  ) async {
    try {
      // 压缩图片
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        filePath,
        quality: quality, // 压缩质量 0-100
        minWidth: minWidth, // 最小宽度 1080
        format: format,
      );
      return compressedBytes ?? typed_data.Uint8List(0);
    } catch (e) {
      AppLogger.error('图片压缩出错', e);
      return typed_data.Uint8List(0);
    }
  }

  ///6、 从内存字节中获取图片尺寸（宽高）
  static Future<(double width, double height)> getImageSizeFromBytes(
    Uint8List bytes,
    AssetEntity asset,
  ) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      return (image.width.toDouble(), image.height.toDouble());
    } catch (error, stackTrace) {
      AppLogger.error('getImageSizeFromBytes', error, stackTrace);
      return (asset.width.toDouble(), asset.height.toDouble());
    }
  }
}
