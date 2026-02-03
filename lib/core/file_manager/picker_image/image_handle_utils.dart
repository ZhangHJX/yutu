import 'package:common/common.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:voicetemplate/core/file_manager/directory_path/index.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

class ImageHandleUtils {
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
    try {
      // 优先拿原图
      File? originalFile = await asset.originFile;
      originalFile ??= await asset.file;
      if (originalFile == null) {
        return "";
      }

      final baseName = p.basenameWithoutExtension(originalFile.path);
      final ext = getFileExtensionFromPath(originalFile.path);
      final tempDir = await DirectoryManager.getTempSubDirectory("images");
      // 使用时间戳避免同名文件覆盖
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueName = '${baseName}_$timestamp';

      AppLogger.info('==复制到指定目录下==${tempDir.path}==$baseName==$ext==');

      if (ext == 'gif') {
        Uint8List? origin = await asset.originBytes;
        // origin 为空时尝试从已取得的文件读取
        if ((origin == null || origin.isEmpty) && await originalFile.exists()) {
          origin = await originalFile.readAsBytes();
        }
        if (origin == null || origin.isEmpty) {
          return '';
        }
        final bytes = await ImageHandleUtils.gifToPngFrame(origin);
        if (bytes == null || bytes.isEmpty) {
          return '';
        }
        final fullPath = p.join(tempDir.path, '$uniqueName.png');
        final file = File(fullPath);
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } else {
        final fullPath = p.join(tempDir.path, '$uniqueName.$ext');

        AppLogger.info('==选择后图片copy的地址==$fullPath==');

        await originalFile.copy(fullPath);
        return fullPath;
      }
    } catch (e, s) {
      AppLogger.error('getAssetImageFilePath 异常:', e, s);
      return '';
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
      AppLogger.info(
        'getAssetFileSize: 文件大小 = $length byte, asset id = ${asset.id}',
      );
      return length;
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
      // 统一使用带点的扩展名拼接，例如 xxx_compressed.png
      final compressedPath = p.join(
        tempDir.path,
        '${fileName}_compressed.$ext',
      );

      AppLogger.info("==$ext==压缩图片文件==路径==$compressedPath==");

      // 根据文件扩展名选择压缩格式（ext 为不带点的小写）
      CompressFormat format = CompressFormat.jpeg;
      if (ext == 'png') {
        format = CompressFormat.png;
      } else if (ext == 'webp') {
        format = CompressFormat.webp;
      } else if (ext == 'heic') {
        format = CompressFormat.heic;
      }

      int quality = 90; // 初始压缩质量
      int minQuality = 20; // 最低可接受质量
      // fileSize 现在是字节数
      int imageSize = fileSize;

      Uint8List compressedBytes = Uint8List(0);

      // 压缩图片
      while (imageSize > maxSizeInMB && quality >= minQuality) {
        compressedBytes = await compressFile(
          filePath,
          format,
          quality,
          minQuality,
          minQuality,
        );
        imageSize = compressedBytes.length;
        quality -= 10;
      }

      if (compressedBytes.isNotEmpty) {
        // 将压缩后的数据写入临时文件
        final compressedFile = File(compressedPath);
        await compressedFile.writeAsBytes(compressedBytes);
        final imgInfo = await getImageSizeFromBytes(compressedBytes, asset);
        // 返回压缩后文件的真实字节数
        final compressedSize = await compressedFile.length();
        return (compressedPath, imgInfo.$1, imgInfo.$2, compressedSize);
      } else {
        // 压缩失败，返回原文件路径
        AppLogger.info('🤯🤯🤯图片压缩失败，使用原文件: $filePath');
        return (
          filePath,
          asset.width.toDouble(),
          asset.height.toDouble(),
          imageSize,
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
  static Future<Uint8List> compressFile(
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
      return compressedBytes ?? Uint8List(0);
    } catch (e) {
      AppLogger.error('图片压缩出错', e);
      return Uint8List(0);
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

  ///7、 gif转图片
  static Future<Uint8List?> gifToPngFrame(
    Uint8List gifBytes, {
    int frameIndex = 0,
  }) async {
    // 直接解码指定帧，而不是解码整个动画
    final frameImage = img.decodeGif(gifBytes, frame: frameIndex);
    if (frameImage == null) {
      return null;
    }

    return Uint8List.fromList(img.encodePng(frameImage));
  }
}
