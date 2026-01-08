import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/file/index.dart';
import '../../canvas/draft/manager/draft_store.dart';

/// 资源文件下载服务
/// 负责下载和管理模板资源文件
/// 区分草稿和模板两种场景
class ResourceDownloadService {
  ResourceDownloadService._();
  static final ResourceDownloadService instance = ResourceDownloadService._();

  /// 当前正在进行的下载任务ID（用于取消）
  String? _currentResourceTaskId;

  final FileDownloader _downloader = FileDownloader();

  /// 检查草稿资源文件是否存在
  /// 根据 id 查找数据库，如果有数据，比较时间戳
  /// 返回 (是否存在, 时间戳是否匹配)
  Future<(bool exists, bool timestampMatches)> checkDraftResourceExists(
    int id,
    int editTime,
  ) async {
    try {
      // 1. 检查数据库是否有这条数据
      final draftModel = await DraftStore.instance.getById(id);
      if (draftModel == null) {
        debugPrint('ResourceDownloadService: 草稿 $id 在数据库中不存在');
        return (false, false);
      }

      // 2. 比较数据库中的时间戳和 MiddleModel 中的 editTime
      final timestampMatches = draftModel.timestamp == editTime;
      if (!timestampMatches) {
        debugPrint(
          'ResourceDownloadService: 草稿 $id 时间戳不匹配，数据库: ${draftModel.timestamp}, 需要: $editTime',
        );
        return (true, false);
      }

      // 3. 检查文件是否存在
      final supportDir = await DirectoryManager.getSupportDirectory();
      final draftDir = Directory(
        p.join(supportDir.path, 'sqflite_draft', '$id'),
      );
      final exists = await draftDir.exists();

      if (exists) {
        debugPrint('ResourceDownloadService: 草稿 $id 存在且时间戳匹配');
        return (true, true);
      } else {
        debugPrint('ResourceDownloadService: 草稿 $id 数据库存在但文件不存在');
        return (true, false);
      }
    } catch (e) {
      debugPrint('ResourceDownloadService: 检查草稿资源失败: $e');
      return (false, false);
    }
  }

  /// 检查模板资源文件是否存在（解压后是目录）
  Future<bool> checkTemplateResourceExists(int id, int editTime) async {
    final resourcePath = await _getTemplateResourceFilePath(id, editTime);
    final resourceDir = Directory(resourcePath);
    return await resourceDir.exists();
  }

  /// 获取模板资源文件路径（文件名格式：id_editTime）
  Future<String> _getTemplateResourceFilePath(int id, int editTime) async {
    final dir = await DirectoryManager.getSupportSubDirectory('templates');
    return p.join(dir.path, '${id}_$editTime');
  }

  /// 获取草稿资源文件路径（文件名格式：id）
  Future<String> _getDraftResourceFilePath(int id) async {
    final supportDir = await DirectoryManager.getSupportDirectory();
    return p.join(supportDir.path, 'sqflite_draft', '$id');
  }

  /// 取消当前正在进行的资源文件下载
  Future<void> cancelResourceDownload() async {
    if (_currentResourceTaskId != null) {
      try {
        await _downloader.cancelTaskWithId(_currentResourceTaskId!);
        debugPrint(
          'ResourceDownloadService: 已取消资源文件下载任务: $_currentResourceTaskId',
        );
      } catch (e) {
        debugPrint('ResourceDownloadService: 取消资源文件下载失败: $e');
      } finally {
        _currentResourceTaskId = null;
      }
    }
  }

  /// 下载草稿资源文件
  /// 如果数据库中有数据且时间戳匹配，直接使用本地文件
  /// 否则下载并解压
  Future<String> downloadDraftResource(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    // 1. 检查数据库和文件
    final (exists, timestampMatches) = await checkDraftResourceExists(
      id,
      editTime,
    );

    if (exists && timestampMatches) {
      // 时间戳匹配，直接使用本地文件
      debugPrint('ResourceDownloadService: 草稿 $id 时间戳匹配，使用本地文件');
      onProgress?.call(1.0);
      return await _getDraftResourceFilePath(id);
    }

    // 2. 需要下载
    if (resourcesUrl.isEmpty) {
      throw Exception('ResourceDownloadService: 资源URL为空');
    }

    debugPrint('ResourceDownloadService: 开始下载草稿资源文件 $id');

    // 3. 创建临时下载目录
    final tempDir = await DirectoryManager.getTempSubDirectory(
      'template_download',
    );
    final zipFilePath = p.join(tempDir.path, '${id}_$editTime.zip');

    try {
      // 4. 下载压缩包
      onProgress?.call(0.1);
      await _downloadZipFile(resourcesUrl, zipFilePath, (progress) {
        onProgress?.call(0.1 + progress * 0.4); // 10-50%
      }, shouldCancel);

      onProgress?.call(0.5);

      // 5. 解压资源文件到 sqflite_draft/{id}
      await _extractDraftZip(zipFilePath, id, (progress) {
        onProgress?.call(0.5 + progress * 0.5); // 50-100%
      });

      onProgress?.call(1.0);
      debugPrint('ResourceDownloadService: 草稿资源文件 $id 下载完成');

      return await _getDraftResourceFilePath(id);
    } catch (e) {
      debugPrint('ResourceDownloadService: 草稿资源文件下载失败: $e');
      rethrow;
    } finally {
      // 清理临时文件
      try {
        await FileManager.deleteFileByPath(zipFilePath);
      } catch (e) {
        debugPrint('ResourceDownloadService: 清理临时文件失败: $e');
      }
    }
  }

  /// 下载模板资源文件
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
      debugPrint('ResourceDownloadService: 模板资源文件 ${id}_$editTime 已存在，跳过下载');
      onProgress?.call(1.0);
      return await _getTemplateResourceFilePath(id, editTime);
    }

    // 2. 需要下载
    if (resourcesUrl.isEmpty) {
      throw Exception('ResourceDownloadService: 资源URL为空');
    }

    debugPrint('ResourceDownloadService: 开始下载模板资源文件 ${id}_$editTime');

    // 3. 创建临时下载目录
    final tempDir = await DirectoryManager.getTempSubDirectory(
      'template_download',
    );
    final zipFilePath = p.join(tempDir.path, '${id}_$editTime.zip');

    try {
      // 4. 下载压缩包
      onProgress?.call(0.1);
      await _downloadZipFile(resourcesUrl, zipFilePath, (progress) {
        onProgress?.call(0.1 + progress * 0.4); // 10-50%
      }, shouldCancel);

      onProgress?.call(0.5);

      // 5. 解压资源文件到 templates/{id}_editTime
      await _extractTemplateZip(zipFilePath, id, editTime, (progress) {
        onProgress?.call(0.5 + progress * 0.5); // 50-100%
      });

      onProgress?.call(1.0);
      debugPrint('ResourceDownloadService: 模板资源文件 ${id}_$editTime 下载完成');

      return await _getTemplateResourceFilePath(id, editTime);
    } catch (e) {
      debugPrint('ResourceDownloadService: 模板资源文件下载失败: $e');
      rethrow;
    } finally {
      // 清理临时文件
      try {
        await FileManager.deleteFileByPath(zipFilePath);
      } catch (e) {
        debugPrint('ResourceDownloadService: 清理临时文件失败: $e');
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
          'ResourceDownloadService: 下载失败: ${result.status}, ${result.exception}',
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

      debugPrint('ResourceDownloadService: 压缩包下载完成: $savePath');
    } catch (e) {
      _currentResourceTaskId = null;
      debugPrint('ResourceDownloadService: 下载压缩包失败: $e');
      rethrow;
    }
  }

  /// 解压草稿资源文件到目标目录 (sqflite_draft/)
  /// 解压后如果顶层目录名为 cavals，则重命名为当前草稿 id（sqflite_draft/{id}）
  Future<void> _extractDraftZip(
    String zipPath,
    int id,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('ResourceDownloadService: 压缩包文件不存在: $zipPath');
      }

      // 获取草稿资源文件目录
      final supportDir = await DirectoryManager.getSupportDirectory();
      final targetDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        p.join('sqflite_draft'),
      );

      // 如果目标目录已存在且有内容，先清空（处理旧版本，使用 FileManager）
      if (await targetDir.exists()) {
        await FileManager.deleteDirectory(targetDir, deleteDirectory: false);
      }

      onProgress?.call(0.2);

      // 解压到目标目录（SupportDirectory/sqflite_draft）
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: targetDir,
      );

      // 解压后，将目录名 cavals 重命名为 id（sqflite_draft/{id}）
      final cavalsDir = Directory(p.join(targetDir.path, 'cavals'));
      if (await cavalsDir.exists()) {
        final idDir = Directory(p.join(targetDir.path, '$id'));

        // 如果同名目录已存在，先删除，避免 rename 失败
        if (await idDir.exists()) {
          await FileManager.deleteDirectory(idDir, deleteDirectory: true);
        }

        await cavalsDir.rename(idDir.path);
      }

      onProgress?.call(1.0);
      debugPrint('ResourceDownloadService: 草稿资源文件解压完成: ${targetDir.path}');
    } catch (e) {
      debugPrint('ResourceDownloadService: 解压草稿资源文件失败: $e');
      rethrow;
    }
  }

  /// 解压模板资源文件到目标目录 (templates/{id}_editTime)
  Future<void> _extractTemplateZip(
    String zipPath,
    int id,
    int editTime,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('ResourceDownloadService: 压缩包文件不存在: $zipPath');
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
      debugPrint('ResourceDownloadService: 模板资源文件解压完成: ${targetDir.path}');
    } catch (e) {
      debugPrint('ResourceDownloadService: 解压模板资源文件失败: $e');
      rethrow;
    }
  }

  /// 将资源文件复制到 Documents/cavals 目录
  /// 将 sourcePath 目录的内容直接复制到 Documents/cavals
  /// 注意：sourcePath 目录的内容就是 cavals 的内容（zip 解压后的内容）
  Future<void> copyResourceToCavals(String sourcePath) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        debugPrint('ResourceDownloadService: 源目录不存在: $sourcePath');
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
      await _copyDirectoryRecursive(sourceDir, targetCavalsDir);

      debugPrint(
        'ResourceDownloadService: 资源文件已复制到 Documents/cavals: ${targetCavalsDir.path}',
      );
    } catch (e) {
      debugPrint('ResourceDownloadService: 复制资源文件到 cavals 失败: $e');
      rethrow;
    }
  }

  /// 递归复制目录及其所有内容
  Future<void> _copyDirectoryRecursive(
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
        await _copyDirectoryRecursive(entity, targetSubDir);
      }
    }
  }
}
