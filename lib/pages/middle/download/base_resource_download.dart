import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/core/file_manager/directory_path/index.dart';

/// 基础资源下载服务
/// 包含草稿和模板共用的下载和文件操作方法
abstract class BaseResourceDownload {
  /// 当前正在进行的下载任务ID（用于取消）
  String? _currentResourceTaskId;

  final FileDownloader _downloader = FileDownloader();

  /// 获取当前下载任务ID
  String? get currentResourceTaskId => _currentResourceTaskId;

  /// 设置当前下载任务ID
  void setCurrentResourceTaskId(String? taskId) {
    _currentResourceTaskId = taskId;
  }

  /// 下载压缩包文件
  Future<void> downloadZipFile(
    String url,
    String savePath, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    try {
      final taskId = 'template_${DateTime.now().millisecondsSinceEpoch}';
      _currentResourceTaskId = taskId;

      final task = DownloadTask(
        url: url,
        filename: p.basename(savePath),
        baseDirectory: BaseDirectory.temporary,
        directory: 'template_download',
        updates: Updates.statusAndProgress,
        taskId: taskId,
      );

      final targetPath = await task.filePath();

      // 如果文件已存在，先删除（使用 FileManager）
      await FileManager.deleteFileByPath(targetPath);

      // 检查是否应该取消
      if (shouldCancel != null && shouldCancel()) {
        _currentResourceTaskId = null;
        throw Exception('下载已取消');
      }

      final result = await _downloader.download(
        task,
        onProgress: (progress) {
          // 检查是否应该取消
          if (shouldCancel != null && shouldCancel()) {
            _downloader.cancelTaskWithId(taskId);
            return;
          }
          onProgress?.call(progress.clamp(0.0, 1.0));
        },
      );

      _currentResourceTaskId = null;

      if (result.status != TaskStatus.complete) {
        // 如果是取消操作
        if (result.status == TaskStatus.canceled) {
          throw Exception('下载已取消');
        }
        throw Exception(
          'BaseResourceDownloadService: 下载失败: ${result.status}, ${result.exception}',
        );
      }

      // 将下载的文件移动到目标路径
      if (targetPath != savePath) {
        final downloadedFile = File(targetPath);
        if (await downloadedFile.exists()) {
          await downloadedFile.copy(savePath);
          // 使用 FileManager 删除原文件
          await FileManager.deleteFileByPath(targetPath);
        }
      }

      AppLogger.info('BaseResourceDownloadService: 压缩包下载完成: $savePath');
    } catch (e) {
      _currentResourceTaskId = null;
      AppLogger.error('BaseResourceDownloadService: 下载压缩包失败:', e);
      rethrow;
    }
  }

  /// 取消当前正在进行的资源文件下载
  Future<void> cancelResourceDownload() async {
    if (_currentResourceTaskId != null) {
      try {
        await _downloader.cancelTaskWithId(_currentResourceTaskId!);
        AppLogger.info(
          'BaseResourceDownloadService: 已取消资源文件下载任务: $_currentResourceTaskId',
        );
      } catch (e) {
        AppLogger.error('BaseResourceDownloadService: 取消资源文件下载失败:', e);
      } finally {
        _currentResourceTaskId = null;
      }
    }
  }

  /// 递归复制目录及其所有内容
  Future<void> copyDirectoryRecursive(
    Directory source,
    Directory destination,
  ) async {
    // 确保目标目录存在
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    // 遍历源目录中的所有内容
    await for (final entity in source.list(recursive: false)) {
      final fileName = p.basename(entity.path);
      final targetPath = p.join(destination.path, fileName);

      if (entity is File) {
        // 复制文件
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        // 递归复制子目录
        final targetSubDir = Directory(targetPath);
        await copyDirectoryRecursive(entity, targetSubDir);
      }
    }
  }

  /// 将资源文件复制到 Documents/cavals 目录
  /// 将 sourcePath 目录的内容直接复制到 Documents/cavals
  /// 注意：sourcePath 目录的内容就是 cavals 的内容（zip 解压后的内容）
  Future<void> copyResourceToCavals(String sourcePath) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        AppLogger.info('BaseResourceDownloadService: 源目录不存在: $sourcePath');
        return;
      }

      // 获取 Documents/cavals 目录
      final documentsDir = await DirectoryManager.getDocumentsDirectory();
      final targetCavalsDir = Directory(p.join(documentsDir.path, 'cavals'));

      // 如果目标目录已存在，先删除（使用 FileManager）
      if (await targetCavalsDir.exists()) {
        await FileManager.deleteDirectory(
          targetCavalsDir,
          deleteDirectory: true,
        );
      }

      // 将 sourceDir 目录的内容直接复制到 Documents/cavals
      // 因为 zip 解压后的内容就是 cavals 的内容，不需要查找子文件夹
      await copyDirectoryRecursive(sourceDir, targetCavalsDir);

      AppLogger.info(
        'BaseResourceDownloadService: 资源文件已复制到 Documents/cavals: ${targetCavalsDir.path}',
      );
    } catch (e) {
      AppLogger.error('BaseResourceDownloadService: 复制资源文件到 cavals 失败:', e);
      rethrow;
    }
  }
}
