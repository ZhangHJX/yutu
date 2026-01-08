import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/file/index.dart';
import 'base_resource_download.dart';

/// 模板资源文件下载服务
/// 负责下载和管理模板资源文件
class TemplateResourceDownload extends BaseResourceDownload {
  TemplateResourceDownload._();
  static final TemplateResourceDownload instance = TemplateResourceDownload._();

  /// 检查模板资源文件是否存在（解压后是目录）
  Future<bool> checkTemplateResourceExists(int id, int editTime) async {
    final resourcePath = await getTemplateResourceFilePath(id, editTime);
    final resourceDir = Directory(resourcePath);
    return await resourceDir.exists();
  }

  /// 获取模板资源文件路径（文件名格式：id_editTime）
  Future<String> getTemplateResourceFilePath(int id, int editTime) async {
    final dir = await DirectoryManager.getSupportSubDirectory('templates');
    return p.join(dir.path, '${id}_$editTime');
  }

  /// 下载模板资源文件
  /// 如果文件已存在，跳过下载
  /// 否则下载并解压到 templates/{id}_editTime
  Future<String> downloadTemplateResource(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    // 1. 检查资源文件是否已存在
    final exists = await checkTemplateResourceExists(id, editTime);
    if (exists) {
      debugPrint(
        'TemplateResourceDownloadService: 模板资源文件 ${id}_$editTime 已存在，跳过下载',
      );
      onProgress?.call(1.0);
      return await getTemplateResourceFilePath(id, editTime);
    }

    // 2. 需要下载
    if (resourcesUrl.isEmpty) {
      throw Exception('TemplateResourceDownloadService: 资源URL为空');
    }

    debugPrint('TemplateResourceDownloadService: 开始下载模板资源文件 ${id}_$editTime');

    // 3. 创建临时下载目录
    final tempDir = await DirectoryManager.getTempSubDirectory(
      'template_download',
    );
    final zipFilePath = p.join(tempDir.path, '${id}_$editTime.zip');

    try {
      // 4. 下载压缩包
      onProgress?.call(0.1);
      await downloadZipFile(
        resourcesUrl,
        zipFilePath,
        onProgress: (progress) {
          onProgress?.call(0.1 + progress * 0.4); // 10-50%
        },
        shouldCancel: shouldCancel,
      );

      onProgress?.call(0.5);

      // 5. 解压资源文件到 templates/{id}_editTime
      await extractTemplateZip(zipFilePath, id, editTime, (progress) {
        onProgress?.call(0.5 + progress * 0.5); // 50-100%
      });

      onProgress?.call(1.0);
      debugPrint(
        'TemplateResourceDownloadService: 模板资源文件 ${id}_$editTime 下载完成',
      );

      return await getTemplateResourceFilePath(id, editTime);
    } catch (e) {
      debugPrint('TemplateResourceDownloadService: 模板资源文件下载失败: $e');
      rethrow;
    } finally {
      // 清理临时文件
      try {
        await FileManager.deleteFileByPath(zipFilePath);
      } catch (e) {
        debugPrint('TemplateResourceDownloadService: 清理临时文件失败: $e');
      }
    }
  }

  /// 解压模板资源文件到目标目录 (templates/{id}_editTime)
  Future<void> extractTemplateZip(
    String zipPath,
    int id,
    int editTime,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('TemplateResourceDownloadService: 压缩包文件不存在: $zipPath');
      }

      // 获取模板资源文件目录
      final templatesDir = await DirectoryManager.getSupportSubDirectory(
        'templates',
      );
      final targetDir = await DirectoryManager.getOrCreateSubDirectory(
        templatesDir,
        '${id}_$editTime',
      );

      // 如果目标目录已存在且有内容，先清空（处理旧版本，使用 FileManager）
      if (await targetDir.exists()) {
        await FileManager.deleteDirectory(targetDir, deleteDirectory: false);
      }

      onProgress?.call(0.2);

      // 解压到目标目录
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: targetDir,
      );

      onProgress?.call(1.0);
      debugPrint(
        'TemplateResourceDownloadService: 模板资源文件解压完成: ${targetDir.path}',
      );
    } catch (e) {
      debugPrint('TemplateResourceDownloadService: 解压模板资源文件失败: $e');
      rethrow;
    }
  }
}
