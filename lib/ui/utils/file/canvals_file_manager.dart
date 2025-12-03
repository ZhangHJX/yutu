import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

/// 本地文件管理工具（单例）
/// - 初始化应用目录
/// - 获取常用路径（文档目录、缓存目录）
class CanvalsFileManager {
  static const List<String> _imageExtensions = <String>[
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
  ];

  /// 生成图片路径
  static Future<String> getImagePath(String canvalsID) async {
    final Directory imageDirectory = await getImagesDirectory(canvalsID);
    final int timestampMillis = DateTime.now().millisecondsSinceEpoch;
    final String fileName = '$timestampMillis.jpg';
    final imagePath = p.join(imageDirectory.path, fileName);
    return imagePath;
  }

  // 已有：获取 cavals/images 目录
  static Future<Directory> getImagesDirectory(String canvalsID) async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String imagesDirectoryPath = p.join(
      documentsDirectory.path,
      'cavals',
      canvalsID,
    );

    final Directory imagesDirectory = Directory(imagesDirectoryPath);

    if (await imagesDirectory.exists()) {
      return imagesDirectory;
    }

    await imagesDirectory.create(recursive: true);
    return imagesDirectory;
  }

  /// 已有：根据完整路径删除单个文件
  static Future<bool> deleteFileByPath(String filePath) async {
    final File targetFile = File(filePath);
    final bool isExist = await targetFile.exists();
    if (!isExist) {
      debugPrint('文件本身就不存在: $filePath');
      return false;
    }
    try {
      await targetFile.delete();
      debugPrint('文件删除成功: $filePath');
      return true;
    } catch (error, stackTrace) {
      debugPrint('删除文件报错: $error\n$stackTrace');
      return false;
    }
  }

  /// 新增：删除 cavals/images 目录下的所有图片文件
  /// 返回实际删除的文件数量
  static Future<int> deleteAllImagesInCavals(String canvalsID) async {
    final Directory imagesDirectory = await getImagesDirectory(canvalsID);

    final bool dirExists = await imagesDirectory.exists();
    if (!dirExists) {
      debugPrint('cavals/images 目录不存在，无需删除');
      return 0;
    }

    int deletedCount = 0;

    try {
      await for (final FileSystemEntity entity in imagesDirectory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is! File) {
          // 只删除文件，不处理子目录
          continue;
        }

        final String filePath = entity.path;
        final String lowerPath = filePath.toLowerCase();

        // 只删除图片类型
        final bool isImage = _imageExtensions.any(
          (String ext) => lowerPath.endsWith(ext),
        );
        if (!isImage) {
          continue;
        }

        try {
          await entity.delete();
          deletedCount++;
          debugPrint('已删除图片: $filePath');
        } catch (error, stackTrace) {
          debugPrint('删除图片失败: $filePath, error: $error\n$stackTrace');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('遍历 cavals/images 目录失败: $error\n$stackTrace');
    }

    debugPrint('cavals/images 图片删除完成，共删除 $deletedCount 个文件');
    return deletedCount;
  }
}
