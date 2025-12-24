import 'dart:io';

import 'package:common/common.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/ui/utils/file/picker_image_manager.dart';

/// 画布图片管理器
///
/// 负责：
/// - 判断图片是否已下载到 Documents/localAsset
/// - 如未下载则使用 background_downloader 下载到 localAsset
/// - 再将图片拷贝到 Documents/cavals/images 目录
/// - 返回画布使用的相对路径（文件名）
class CanvalsImageManager {
  CanvalsImageManager._();

  static final CanvalsImageManager instance = CanvalsImageManager._();

  /// 确保图片已经拷贝到 cavals/images，并返回画布使用的文件名
  ///
  /// [imageUrl] 网络图片地址
  /// 返回值：画布中使用的 filePath（仅文件名，配合 PickerImageManager.loadCanvalsImage 使用）
  Future<String> ensureImageInCanvasImages(String imageUrl) async {
    // 1. 先确保图片在 Documents/localAsset 下存在（如无则下载）
    final File localAssetFile = await _ensureInLocalAsset(imageUrl);

    // 2. 再将该文件拷贝到 Documents/cavals/images
    final String fileName = p.basename(localAssetFile.path);

    // cavals/images 目录（已经在 PickerImageManager.init 中初始化过）
    final Directory cavalsDir = Directory(PickerImageManager.cavalsPath);
    if (!await cavalsDir.exists()) {
      await cavalsDir.create(recursive: true);
    }

    final String targetPath = p.join(cavalsDir.path, fileName);
    final File targetFile = File(targetPath);

    // 如果目标文件已存在，可以选择覆盖或直接复用
    if (!await targetFile.exists()) {
      await localAssetFile.copy(targetPath);
    }

    // 返回给画布使用的“相对路径”（仅文件名）
    return fileName;
  }

  /// 确保图片已经在 Documents/localAsset 中存在，返回该文件
  ///
  /// - 如果已存在，则直接返回
  /// - 如果不存在，则通过 background_downloader 下载到本地后返回
  Future<File> _ensureInLocalAsset(String imageUrl) async {
    // 使用 URL 的路径部分作为文件名
    final Uri uri = Uri.parse(imageUrl);
    String fileName = p.basename(uri.path);
    if (fileName.isEmpty) {
      // 兜底：如果 URL 没有文件名，使用时间戳命名
      fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    }

    // 使用 background_downloader，将文件保存到：
    // applicationDocumentsDirectory/localAsset/<fileName>
    final String taskId =
        'material_${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}';

    final task = DownloadTask(
      url: imageUrl,
      filename: fileName,
      baseDirectory: BaseDirectory.applicationDocuments,
      directory: 'localAsset',
      updates: Updates.statusAndProgress,
      taskId: taskId,
    );

    final String targetPath = await task.filePath();
    final File targetFile = File(targetPath);

    // 如果已经存在，直接返回，认为已经下载过
    if (await targetFile.exists()) {
      return targetFile;
    }

    final downloader = FileDownloader();

    double lastProgress = 0.0;
    final result = await downloader.download(
      task,
      onProgress: (progress) {
        // 这里暂时不透出进度，只做容错处理
        final clamped = progress.clamp(0.0, 1.0);
        if (clamped >= lastProgress || clamped == 0.0) {
          lastProgress = clamped;
        }
      },
    );

    if (result.status != TaskStatus.complete) {
      // 失败时尝试清理任务和文件
      try {
        await downloader.cancelTaskWithId(taskId);
      } catch (_) {}

      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      throw Exception(
        'CanvalsImageManager: 图片下载失败，status=${result.status}, url=$imageUrl',
      );
    }

    if (!await targetFile.exists()) {
      throw Exception('CanvalsImageManager: 下载完成但本地文件不存在，path=$targetPath');
    }

    final int size = await targetFile.length();
    if (size <= 0) {
      try {
        await targetFile.delete();
      } catch (_) {}
      throw Exception('CanvalsImageManager: 下载文件为空 (0 bytes), url=$imageUrl');
    }

    return targetFile;
  }
}
