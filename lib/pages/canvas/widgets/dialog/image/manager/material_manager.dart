import 'package:common/common.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/core/index.dart';
import 'dart:io';
import 'local_asset_store.dart';

/// 画布图片管理器
class MaterialManager {
  MaterialManager._();
  static final MaterialManager instance = MaterialManager._();

  /// 进来就说明不存在，直接进行下载
  Future<void> ensureImageInLocalAsset(
    String imageUrl,
    String fileName,
    String targetPath,
  ) async {
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
  }

  /// 确保图片已经拷贝到 cavals/images，并返回画布使用的文件名
  /// 返回值：画布中使用的 filePath（仅文件名，配合 PickerImageManager.loadCanvalsImage 使用）
  Future<void> ensureImageInCanvasImages(
    File localAssetFile,
    String fileName,
  ) async {
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
  }

  /// 删除 localAsset 目录下除数据库外的全部或部分图片
  Future<void> deleteAllMaterial() async {
    final localAssetDir = await DirectoryManager.getSupportSubDirectory(
      'localAsset',
    );
    const dbFileName = 'localAsset.db';
    if (!await localAssetDir.exists()) return;
    // 清空数据库
    await LocalAssetStore.instance.clearAll();
    final entities = localAssetDir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name != dbFileName) {
          try {
            await entity.delete();
          } catch (e) {
            AppLogger.error(
              'MaterialManager: 删除本地图片失败, path=${entity.path}',
              e,
            );
          }
        }
      }
    }
  }

  // 删除部分
  Future<void> deletePartMaterial(String fileName) async {
    if (fileName.isEmpty) return;
    final localAssetDir = await DirectoryManager.getSupportSubDirectory(
      'localAsset',
    );
    await LocalAssetStore.instance.deleteByFileName(fileName);

    final filePath = p.join(localAssetDir.path, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        AppLogger.error('MaterialManager: 删除本地图片失败, path=$filePath', e);
      }
    }
  }
}
