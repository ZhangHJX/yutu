import 'dart:io';

import 'package:common/common.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/core/index.dart';

/// 画布图片管理器
///
/// 负责：
/// - 判断图片是否已下载到 Application Support/localAsset
/// - 如未下载则使用 background_downloader 下载到 localAsset
/// - 再将图片拷贝到 Documents/cavals/images 目录
/// - 返回画布使用的相对路径（文件名）
class MaterialManager {
  MaterialManager._();
  static final MaterialManager instance = MaterialManager._();

  /// 确保图片已经拷贝到 cavals/images，并返回画布使用的文件名
  ///
  /// [imageUrl] 网络图片地址
  /// 返回值：画布中使用的 filePath（仅文件名，配合 PickerImageManager.loadCanvalsImage 使用）
  Future<String> ensureImageInCanvasImages(String imageUrl) async {
    // 1. 先确保图片在 Application Support/localAsset 下存在（如无则下载）
    final File localAssetFile = await ensureImageInLocalAsset(imageUrl);

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

    // 返回给画布使用的"相对路径"（仅文件名）
    return fileName;
  }

  /// 确保图片已经在 Application Support/localAsset 中存在，返回该文件
  ///
  /// - 如果已存在，则直接返回
  /// - 如果不存在，则通过 background_downloader 下载到本地后返回
  ///
  /// 注意：使用 imageUrl 中的文件名（从 URL 路径提取），应与上传时使用的 ossModel.file 保持一致
  Future<File> ensureImageInLocalAsset(String imageUrl) async {
    // 使用 ImageModel 中 image URL 的路径部分作为文件名
    final fileName = Uri.parse(imageUrl).pathSegments.last;
    // 获取 Application Support/localAsset 目录（不存在则创建）
    final localAssetDir = await DirectoryManager.getSupportSubDirectory(
      'localAsset',
    );
    final String targetPath = p.join(localAssetDir.path, fileName);
    final File targetFile = File(targetPath);

    // 如果已经存在，直接返回，认为已经下载过
    if (await targetFile.exists()) {
      return targetFile;
    }

    // 使用 background_downloader 下载到 Application Support/localAsset
    final String taskId =
        'material_${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}';

    // background_downloader 不支持直接下载到 Application Support，需要先下载到临时目录再移动
    // 先下载到 Documents 临时目录
    final tempTask = DownloadTask(
      url: imageUrl,
      filename: fileName,
      baseDirectory: BaseDirectory.applicationDocuments,
      directory: 'localAsset_temp',
      updates: Updates.statusAndProgress,
      taskId: taskId,
    );

    final String tempPath = await tempTask.filePath();
    final File tempFile = File(tempPath);

    // 确保临时目录存在
    await Directory(p.dirname(tempPath)).create(recursive: true);

    final downloader = FileDownloader();

    double lastProgress = 0.0;
    final result = await downloader.download(
      tempTask,
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

      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      throw Exception(
        'CanvalsImageManager: 图片下载失败，status=${result.status}, url=$imageUrl',
      );
    }

    if (!await tempFile.exists()) {
      throw Exception('CanvalsImageManager: 下载完成但临时文件不存在，path=$tempPath');
    }

    final int size = await tempFile.length();
    if (size <= 0) {
      try {
        await tempFile.delete();
      } catch (_) {}
      throw Exception('CanvalsImageManager: 下载文件为空 (0 bytes), url=$imageUrl');
    }

    // 将文件从临时目录移动到 Application Support/localAsset
    await tempFile.copy(targetPath);

    // 清理临时文件
    try {
      await tempFile.delete();
      // 尝试清理临时目录（如果为空）
      final tempDir = Directory(p.dirname(tempPath));
      try {
        await tempDir.delete(recursive: false);
      } catch (_) {}
    } catch (_) {}

    return targetFile;
  }
}
