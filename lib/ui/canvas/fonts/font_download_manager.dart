import 'dart:io';

import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../file/index.dart';

/// 负责字体 zip 的下载 + 进度管理
/// - 使用 background_downloader
/// - 保证同一个 fontId 只有一个下载任务（“单飞”）
class FontDownloadManager {
  FontDownloadManager._();

  static final FontDownloadManager instance = FontDownloadManager._();

  /// fontId -> 正在进行的下载 Future
  final Map<int, Future<File>> _ongoing = {};

  /// 下载到临时目录   .../tmp/fonts/<fontId>.zip
  Future<File> downloadFontZip({
    required int fontId,
    required String url,
    ValueChanged<double>? onProgress,
  }) {
    final existing = _ongoing[fontId];
    if (existing != null) return existing;

    final future = _download(fontId: fontId, url: url, onProgress: onProgress);
    _ongoing[fontId] = future;
    future.whenComplete(() {
      _ongoing.remove(fontId);
    });
    return future;
  }

  Future<File> _download({
    required int fontId,
    required String url,
    ValueChanged<double>? onProgress,
  }) async {
    final fontsTmp = await DirectoryManager.getTempSubDirectory('fonts');
    final filePath = p.join(fontsTmp.path, '$fontId.zip');

    final task = DownloadTask(
      url: url,
      filename: '$fontId.zip',
      directory: fontsTmp.path,
    );

    final downloader = FileDownloader();
    await downloader.download(
      task,
      onProgress: (progress) {
        // 0.0 ~ 1.0
        onProgress?.call(progress);
      },
    );

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception(
        'FontDownloadManager: download succeeded but file missing',
      );
    }
    return file;
  }
}
