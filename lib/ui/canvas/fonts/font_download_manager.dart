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
    if (existing != null) return existing;

    final future = _download(fontId: fontId, url: url, onProgress: onProgress);
    _ongoing[fontId] = future;

    future.whenComplete(() => _ongoing.remove(fontId));
    return future;
  }

  Future<File> _download({
    required int fontId,
    required String url,
    ValueChanged<double>? onProgress,
  }) async {
    final task = DownloadTask(
      url: url,
      filename: '$fontId.zip',
      baseDirectory: BaseDirectory.temporary,
      directory: 'fonts', // ✅ 必须是相对目录
      updates: Updates.none,
    );

    final targetPath = await task.filePath(); // ✅ 这里得到正确的绝对路径
    final targetFile = File(targetPath);

    // 如果文件已存在，先删除
    if (await targetFile.exists()) {
      try {
        await targetFile.delete();
      } catch (e) {
        debugPrint('FontDownloadManager: failed to delete existing file: $e');
      }
    }

    final downloader = FileDownloader();

    debugPrint(
      'FontDownloadManager: starting download - fontId: $fontId, url: $url',
    );

    final result = await downloader.download(
      task,
      onProgress: (progress) => onProgress?.call(progress),
    );

    debugPrint(
      'FontDownloadManager: download completed - status: ${result.status}, exception: ${result.exception}',
    );

    if (result.status != TaskStatus.complete) {
      throw Exception(
        'FontDownloadManager: Download failed - status: ${result.status}, exception: ${result.exception}',
      );
    }

    if (!await targetFile.exists()) {
      throw Exception(
        'FontDownloadManager: download succeeded but file missing at $targetPath',
      );
    }

    final size = await targetFile.length();
    if (size <= 0) {
      throw Exception(
        'FontDownloadManager: downloaded file is empty (0 bytes)',
      );
    }

    debugPrint(
      'FontDownloadManager: download successful, size=$size, path=$targetPath',
    );
    return targetFile;
  }
}
