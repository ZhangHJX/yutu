import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/file/index.dart';
import '../canvas/fonts/font_manager.dart';
import '../canvas/fonts/font_meta_store.dart';
import 'model/middle_model.dart';

/// 模板下载服务
/// 负责下载模板的字体和资源文件
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  /// 当前正在进行的下载任务ID（用于取消）
  String? _currentResourceTaskId;

  /// 当前正在下载的字体任务ID映射：fontId -> taskId
  final Map<int, String> _currentFontTaskIds = {};

  final FileDownloader _downloader = FileDownloader();

  /// 检查字体文件是否存在且版本匹配
  Future<bool> checkFontExists(int fontId, String requiredVersion) async {
    final localMeta = await FontMetaStore.instance.readMeta(fontId);
    if (localMeta == null) {
      return false;
    }
    return localMeta.version == requiredVersion;
  }

  /// 下载字体文件
  /// 如果字体不存在或版本不匹配，则下载新版本
  /// 下载完成后，删除旧版本，移动新版本到字体文件夹
  Future<void> downloadFontIfNeeded(
    FontItemModel fontItem, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final fontId = fontItem.frontId;
    final requiredVersion = fontItem.frontVersion;
    final fontUrl = fontItem.frontUrl;

    // 检查字体是否已存在且版本匹配
    final exists = await checkFontExists(fontId, requiredVersion);
    if (exists) {
      debugPrint('DownloadService: 字体 $fontId 版本 $requiredVersion 已存在，跳过下载');
      onProgress?.call(1.0);
      return;
    }

    debugPrint('DownloadService: 开始下载字体 $fontId 版本 $requiredVersion');

    // 生成任务ID用于取消
    final taskId = 'font_${fontId}_${DateTime.now().millisecondsSinceEpoch}';
    _currentFontTaskIds[fontId] = taskId;

    try {
      // 检查是否应该取消
      if (shouldCancel != null && shouldCancel()) {
        _currentFontTaskIds.remove(fontId);
        throw Exception('下载已取消');
      }

      // 使用 FontManager 下载字体（会自动处理版本检查和旧版本删除）
      try {
        await FontManager.to.prepareFont(
          fontId: fontId,
          version: requiredVersion,
          url: fontUrl,
          onProgress: (progress) {
            // 在进度回调中检查是否应该取消
            if (shouldCancel != null && shouldCancel()) {
              // 抛出异常以停止下载流程
              throw Exception('下载已取消');
            }
            onProgress?.call(progress);
          },
        );
      } catch (e) {
        // 如果是取消操作，重新抛出
        if (e.toString().contains('取消')) {
          rethrow;
        }
        // 其他错误也重新抛出
        rethrow;
      }

      _currentFontTaskIds.remove(fontId);
      debugPrint('DownloadService: 字体 $fontId 下载完成');
    } catch (e) {
      _currentFontTaskIds.remove(fontId);
      debugPrint('DownloadService: 字体 $fontId 下载失败: $e');
      rethrow;
    }
  }

  /// 取消所有正在进行的字体下载
  /// 注意：由于无法直接获取 FontDownloadManager 的任务ID，
  /// 实际的取消通过 shouldCancel 标志和抛出异常来实现
  Future<void> cancelAllFontDownloads() async {
    debugPrint('DownloadService: 取消所有字体下载');
    _currentFontTaskIds.clear();
  }

  /// 下载所有需要的字体（并发下载）
  Future<void> downloadFontsIfNeeded(
    List<FontItemModel> frontData, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (frontData.isEmpty) {
      onProgress?.call(1.0);
      return;
    }

    // 检查是否应该取消
    if (shouldCancel != null && shouldCancel()) {
      debugPrint('DownloadService: 字体下载已取消');
      throw Exception('下载已取消');
    }

    final totalFonts = frontData.length;

    // 用于跟踪每个字体的下载进度
    final Map<int, double> fontProgressMap = {};
    for (int i = 0; i < frontData.length; i++) {
      fontProgressMap[i] = 0.0;
    }

    // 更新总进度的辅助函数
    void updateTotalProgress() {
      double totalProgress = 0.0;
      for (final progress in fontProgressMap.values) {
        totalProgress += progress;
      }
      final averageProgress = totalProgress / totalFonts;
      onProgress?.call(averageProgress);
    }

    // 创建所有下载任务（并发执行）
    final List<Future<void>> downloadTasks = [];

    for (int i = 0; i < frontData.length; i++) {
      final fontItem = frontData[i];
      final taskIndex = i;

      // 创建下载任务（不立即 await）
      final task =
          downloadFontIfNeeded(
            fontItem,
            onProgress: (progress) {
              // 更新该字体的进度
              fontProgressMap[taskIndex] = progress;
              // 更新总进度
              updateTotalProgress();
            },
            shouldCancel: shouldCancel,
          ).catchError((e) {
            // 如果是取消操作，直接抛出
            if (e.toString().contains('取消')) {
              throw e;
            }
            debugPrint('DownloadService: 字体 ${fontItem.frontId} 下载失败: $e');
            // 单个字体失败不影响整体流程，标记为完成
            fontProgressMap[taskIndex] = 1.0;
            updateTotalProgress();
            return null;
          });

      downloadTasks.add(task);
    }

    // 等待所有下载任务完成（并发执行）
    try {
      await Future.wait(downloadTasks);
      onProgress?.call(1.0);
    } catch (e) {
      // 如果是取消操作，直接抛出
      if (e.toString().contains('取消')) {
        rethrow;
      }
      // 其他错误也抛出
      rethrow;
    }
  }

  /// 资源文件存储目录名
  static const String _resourcesDirName = 'templates';

  /// 获取资源文件目录
  Future<Directory> _getResourcesDirectory() async {
    return await DirectoryManager.getSupportSubDirectory(_resourcesDirName);
  }

  /// 获取资源文件路径（文件名格式：id_editTime）
  Future<String> _getResourceFilePath(int id, int editTime) async {
    final dir = await _getResourcesDirectory();
    return p.join(dir.path, '${id}_$editTime');
  }

  /// 检查资源文件是否存在（解压后是目录）
  Future<bool> checkResourceFileExists(int id, int editTime) async {
    final resourcePath = await _getResourceFilePath(id, editTime);
    final resourceDir = Directory(resourcePath);
    return await resourceDir.exists();
  }

  /// 取消当前正在进行的资源文件下载
  Future<void> cancelResourceDownload() async {
    if (_currentResourceTaskId != null) {
      try {
        await _downloader.cancelTaskWithId(_currentResourceTaskId!);
        debugPrint('DownloadService: 已取消资源文件下载任务: $_currentResourceTaskId');
      } catch (e) {
        debugPrint('DownloadService: 取消资源文件下载失败: $e');
      } finally {
        _currentResourceTaskId = null;
      }
    }
  }

  /// 取消所有正在进行的下载（字体和资源）
  Future<void> cancelAllDownloads() async {
    await cancelAllFontDownloads();
    await cancelResourceDownload();
  }

  /// 下载资源文件
  Future<void> downloadResourceFile(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (resourcesUrl.isEmpty) {
      throw Exception('DownloadService: 资源URL为空');
    }

    // 检查资源文件是否已存在
    final exists = await checkResourceFileExists(id, editTime);
    if (exists) {
      debugPrint('DownloadService: 资源文件 ${id}_$editTime 已存在，跳过下载');
      onProgress?.call(1.0);
      return;
    }

    debugPrint('DownloadService: 开始下载资源文件 ${id}_$editTime');

    // 1. 创建临时下载目录
    final tempDir = await DirectoryManager.getTempSubDirectory(
      'template_download',
    );
    final zipFilePath = p.join(tempDir.path, '${id}_$editTime.zip');

    try {
      // 2. 下载压缩包
      onProgress?.call(0.1);
      await _downloadZipFile(resourcesUrl, zipFilePath, (progress) {
        onProgress?.call(0.1 + progress * 0.4); // 10-50%
      }, shouldCancel);

      onProgress?.call(0.5);

      // 3. 解压资源文件
      await _extractResourceZip(zipFilePath, id, editTime, (progress) {
        onProgress?.call(0.5 + progress * 0.5); // 50-100%
      });

      onProgress?.call(1.0);
      debugPrint('DownloadService: 资源文件 ${id}_$editTime 下载完成');
    } catch (e) {
      debugPrint('DownloadService: 资源文件下载失败: $e');
      rethrow;
    } finally {
      // 清理临时文件（使用 FileManager）
      try {
        await FileManager.deleteFileByPath(zipFilePath);
      } catch (e) {
        debugPrint('DownloadService: 清理临时文件失败: $e');
      }
    }
  }

  /// 下载压缩包文件
  Future<void> _downloadZipFile(
    String url,
    String savePath,
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  ) async {
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
          'DownloadService: 下载失败: ${result.status}, ${result.exception}',
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

      debugPrint('DownloadService: 压缩包下载完成: $savePath');
    } catch (e) {
      _currentResourceTaskId = null;
      debugPrint('DownloadService: 下载压缩包失败: $e');
      rethrow;
    }
  }

  /// 解压资源文件到目标目录
  Future<void> _extractResourceZip(
    String zipPath,
    int id,
    int editTime,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('DownloadService: 压缩包文件不存在: $zipPath');
      }

      // 获取资源文件目录
      final resourcesDir = await _getResourcesDirectory();
      final targetDir = await DirectoryManager.getOrCreateSubDirectory(
        resourcesDir,
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
      debugPrint('DownloadService: 资源文件解压完成: ${targetDir.path}');
    } catch (e) {
      debugPrint('DownloadService: 解压资源文件失败: $e');
      rethrow;
    }
  }

  /// 获取资源文件路径（用于加载画布）
  Future<String?> getResourceFilePath(int id, int editTime) async {
    final exists = await checkResourceFileExists(id, editTime);
    if (!exists) {
      return null;
    }
    return await _getResourceFilePath(id, editTime);
  }
}
