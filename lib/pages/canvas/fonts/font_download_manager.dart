import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';

/// 负责字体 zip 的下载 + 进度管理
/// - 使用 background_downloader
/// - 保证同一个 fontId 只有一个下载任务（“单飞”）
class FontDownloadManager {
  FontDownloadManager._();

  static final FontDownloadManager instance = FontDownloadManager._();

  /// fontId -> 正在进行的下载 Future
  final Map<int, Future<File>> _ongoing = <int, Future<File>>{};

  /// 下载到临时目录   .../tmp/fonts/fontId.zip
  Future<File> downloadFontZip({
    required int fontId,
    required String url,
    ValueChanged<double>? onProgress,
  }) {
    final existing = _ongoing[fontId];
    if (existing != null) {
      debugPrint(
        'FontDownloadManager: download already in progress for fontId: $fontId',
      );
      return existing;
    }

    final future = _download(fontId: fontId, url: url, onProgress: onProgress);
    _ongoing[fontId] = future;

    future.whenComplete(() {
      _ongoing.remove(fontId);
      debugPrint(
        'FontDownloadManager: download task completed/removed for fontId: $fontId',
      );
    });
    return future;
  }

  Future<File> _download({
    required int fontId,
    required String url,
    ValueChanged<double>? onProgress,
  }) async {
    // 使用唯一的任务ID，避免并发下载时的任务冲突
    final taskId = 'font_${fontId}_${DateTime.now().millisecondsSinceEpoch}';

    final task = DownloadTask(
      url: url,
      filename: '$fontId.zip',
      baseDirectory: BaseDirectory.temporary,
      directory: 'fonts', // ✅ 必须是相对目录
      updates: Updates.statusAndProgress, // 改为statusAndProgress以获取更好的进度更新
      taskId: taskId, // 使用唯一任务ID
    );

    final targetPath = await task.filePath(); // ✅ 这里得到正确的绝对路径
    final targetFile = File(targetPath);

    // 如果文件已存在，先删除
    if (await targetFile.exists()) {
      try {
        await targetFile.delete();
        debugPrint('FontDownloadManager: deleted existing file at $targetPath');
      } catch (e) {
        debugPrint('FontDownloadManager: failed to delete existing file: $e');
      }
    }

    final downloader = FileDownloader();

    debugPrint(
      'FontDownloadManager: starting download - fontId: $fontId, taskId: $taskId, url: $url',
    );

    double lastProgress = 0.0;
    final result = await downloader.download(
      task,
      onProgress: (progress) {
        // 修复进度计算：确保进度在0-1之间，防止负数
        final clampedProgress = progress.clamp(0.0, 1.0);
        // 防止进度回退（除非是重新开始）
        if (clampedProgress >= lastProgress || clampedProgress == 0.0) {
          lastProgress = clampedProgress;
          onProgress?.call(clampedProgress);
        } else {
          // 如果进度回退，使用上次的进度值
          onProgress?.call(lastProgress);
        }
      },
    );

    debugPrint(
      'FontDownloadManager: download completed - fontId: $fontId, taskId: $taskId, status: ${result.status}, exception: ${result.exception}',
    );

    if (result.status != TaskStatus.complete) {
      // 清理失败的任务
      try {
        await downloader.cancelTaskWithId(taskId);
      } catch (e) {
        debugPrint('FontDownloadManager: error cancelling failed task: $e');
      }

      // 如果文件存在但状态不是complete，也删除它
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (e) {
          debugPrint('FontDownloadManager: error deleting incomplete file: $e');
        }
      }

      throw Exception(
        'FontDownloadManager: Download failed - fontId: $fontId, status: ${result.status}, exception: ${result.exception}',
      );
    }

    if (!await targetFile.exists()) {
      throw Exception(
        'FontDownloadManager: download succeeded but file missing at $targetPath',
      );
    }

    final size = await targetFile.length();
    if (size <= 0) {
      // 删除空文件
      try {
        await targetFile.delete();
      } catch (e) {
        debugPrint('FontDownloadManager: error deleting empty file: $e');
      }
      throw Exception(
        'FontDownloadManager: downloaded file is empty (0 bytes)',
      );
    }

    debugPrint(
      'FontDownloadManager: download successful - fontId: $fontId, size=$size, path=$targetPath',
    );
    return targetFile;
  }
}
