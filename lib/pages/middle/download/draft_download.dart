import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/file/index.dart';
import 'base_resource_download.dart';
import '../manager/index.dart';
import '../model/middle_model.dart';

/// 草稿资源文件下载服务
/// 负责下载和管理草稿资源文件
class DraftDownload extends BaseResourceDownload {
  DraftDownload._();
  static final DraftDownload instance = DraftDownload._();

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
        debugPrint('DraftResourceDownloadService: 草稿 $id 在数据库中不存在');
        return (false, false);
      }

      // 2. 比较数据库中的时间戳和 MiddleModel 中的 editTime
      final timestampMatches = draftModel.timestamp == editTime;
      if (!timestampMatches) {
        debugPrint(
          'DraftResourceDownloadService: 草稿 $id 时间戳不匹配，数据库: ${draftModel.timestamp}, 需要: $editTime',
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
        debugPrint('DraftResourceDownloadService: 草稿 $id 存在且时间戳匹配');
        return (true, true);
      } else {
        debugPrint('DraftResourceDownloadService: 草稿 $id 数据库存在但文件不存在');
        return (true, false);
      }
    } catch (e) {
      debugPrint('DraftResourceDownloadService: 检查草稿资源失败: $e');
      return (false, false);
    }
  }

  /// 获取草稿资源文件路径（文件名格式：id）
  Future<String> getDraftResourceFilePath(int id) async {
    final supportDir = await DirectoryManager.getSupportDirectory();
    return p.join(supportDir.path, 'sqflite_draft', '$id');
  }

  /// 下载草稿资源文件
  /// 如果数据库中有数据且时间戳匹配，直接使用本地文件
  /// 否则下载并解压到 sqflite_draft/{id}
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
      debugPrint('DraftResourceDownloadService: 草稿 $id 时间戳匹配，使用本地文件');
      onProgress?.call(1.0);
      return await getDraftResourceFilePath(id);
    }

    // 2. 需要下载
    if (resourcesUrl.isEmpty) {
      throw Exception('DraftResourceDownloadService: 资源URL为空');
    }

    debugPrint('DraftResourceDownloadService: 开始下载草稿资源文件 $id');

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

      // 5. 解压资源文件到 sqflite_draft 目录下
      await extractDraftZip(zipFilePath, id, (progress) {
        onProgress?.call(0.5 + progress * 0.5); // 50-100%
      });

      onProgress?.call(1.0);
      debugPrint('DraftResourceDownloadService: 草稿资源文件 $id 下载完成');

      return await getDraftResourceFilePath(id);
    } catch (e) {
      debugPrint('DraftResourceDownloadService: 草稿资源文件下载失败: $e');
      rethrow;
    } finally {
      // 清理临时文件
      try {
        await FileManager.deleteFileByPath(zipFilePath);
      } catch (e) {
        debugPrint('DraftResourceDownloadService: 清理临时文件失败: $e');
      }
    }
  }

  /// 解压草稿资源文件到目标目录 (sqflite_draft/)
  /// 解压后如果顶层目录名为 cavals，则重命名为当前草稿 id（sqflite_draft/{id}）
  Future<void> extractDraftZip(
    String zipPath,
    int id,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('DraftResourceDownloadService: 压缩包文件不存在: $zipPath');
      }

      // 获取草稿资源文件目录
      final supportDir = await DirectoryManager.getSupportDirectory();
      final targetDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'sqflite_draft',
      );

      // 如果目标目录已存在且有内容，先清空（处理旧版本，使用 FileManager）
      final targetFile = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        p.join('sqflite_draft', '$id'),
      );
      if (await targetFile.exists()) {
        await FileManager.deleteDirectory(targetFile, deleteDirectory: false);
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
      debugPrint('DraftResourceDownloadService: 草稿资源文件解压完成: ${targetDir.path}');
    } catch (e) {
      debugPrint('DraftResourceDownloadService: 解压草稿资源文件失败: $e');
      rethrow;
    }
  }

  /// 保存或更新草稿
  /// [model] 中间页模型
  /// [id] 草稿 id
  /// 返回 true 表示成功，false 表示失败
  /// 注意：此方法仅保存草稿元数据，不包含画布数据
  Future<bool> saveOrUpdateDraft(MiddleModel model) async {
    try {
      // 1. 创建 DraftModel（仅保存元数据，不保存画布数据）
      final draftModel = ManagerModel(id: model.id, timestamp: model.editTime);
      // 2. 保存或更新数据库记录
      final success = await DraftStore.instance.save(draftModel);
      if (!success) {
        debugPrint('DraftResourceDownload: 保存数据库记录失败, id=${model.id}');
        return false;
      }
      debugPrint('DraftResourceDownload: 草稿更新或保存成功, id=${model.id}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('DraftResourceDownload: 保存草稿失败: $e\n$stackTrace');
      return false;
    }
  }
}
