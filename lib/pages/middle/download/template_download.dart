import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/file/index.dart';
import 'base_resource_download.dart';
import '../manager/template_manager/template_store.dart';
import '../manager/manager_model.dart';
import '../model/middle_model.dart';

/// 模板资源文件下载服务
/// 负责下载和管理模板资源文件
class TemplateDownload extends BaseResourceDownload {
  TemplateDownload._();
  static final TemplateDownload instance = TemplateDownload._();

  /// 检查模板资源文件是否存在
  /// 根据 id 查找数据库，如果有数据，比较时间戳
  /// 返回 (是否存在, 时间戳是否匹配)
  Future<(bool exists, bool timestampMatches)> checkTemplateResourceExists(
    int id,
    int editTime,
  ) async {
    try {
      // 1. 检查数据库是否有这条数据
      final templateModel = await TemplateStore.instance.getById(id);
      if (templateModel == null) {
        debugPrint('TemplateDownload: 模板 $id 在数据库中不存在');
        return (false, false);
      }

      // 2. 比较数据库中的时间戳和 MiddleModel 中的 editTime
      final timestampMatches = templateModel.timestamp == editTime;
      if (!timestampMatches) {
        debugPrint(
          'TemplateDownload: 模板 $id 时间戳不匹配，数据库: ${templateModel.timestamp}, 需要: $editTime',
        );
        return (true, false);
      }

      // 3. 检查文件是否存在
      final resourcePath = await getTemplateResourceFilePath(id);
      final resourceDir = Directory(resourcePath);
      final exists = await resourceDir.exists();

      if (exists) {
        debugPrint('TemplateDownload: 模板 $id 存在且时间戳匹配');
        return (true, true);
      } else {
        debugPrint('TemplateDownload: 模板 $id 数据库存在但文件不存在');
        return (true, false);
      }
    } catch (e) {
      debugPrint('TemplateDownload: 检查模板资源失败: $e');
      return (false, false);
    }
  }

  /// 获取模板资源文件路径（文件名格式：id，与草稿一致）
  Future<String> getTemplateResourceFilePath(int id) async {
    final dir = await DirectoryManager.getSupportSubDirectory('templates');
    return p.join(dir.path, '$id');
  }

  /// 下载模板资源文件
  /// 如果数据库中有数据且时间戳匹配，直接使用本地文件
  /// 否则下载并解压到 templates/{id}
  Future<String> downloadTemplateResource(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    // 1. 检查数据库和文件
    final (exists, timestampMatches) = await checkTemplateResourceExists(
      id,
      editTime,
    );

    if (exists && timestampMatches) {
      // 时间戳匹配，直接使用本地文件
      debugPrint('TemplateDownload: 模板 $id 时间戳匹配，使用本地文件');
      onProgress?.call(1.0);
      return await getTemplateResourceFilePath(id);
    }

    // 2. 需要下载
    if (resourcesUrl.isEmpty) {
      throw Exception('TemplateDownload: 资源URL为空');
    }

    debugPrint('TemplateDownload: 开始下载模板资源文件 $id');

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

      // 5. 解压资源文件到 templates/
      await extractTemplateZip(zipFilePath, id, (progress) {
        onProgress?.call(0.5 + progress * 0.5); // 50-100%
      });

      onProgress?.call(1.0);
      debugPrint('TemplateDownload: 模板资源文件 $id 下载完成');

      return await getTemplateResourceFilePath(id);
    } catch (e) {
      debugPrint('TemplateDownload: 模板资源文件下载失败: $e');
      rethrow;
    } finally {
      // 清理临时文件
      try {
        await FileManager.deleteFileByPath(zipFilePath);
      } catch (e) {
        debugPrint('TemplateDownload: 清理临时文件失败: $e');
      }
    }
  }

  /// 解压模板资源文件到目标目录 (templates/{id})
  /// 解压后如果顶层目录名为 cavals，则重命名为当前模板 id（templates/{id}）
  Future<void> extractTemplateZip(
    String zipPath,
    int id,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('TemplateDownload: 压缩包文件不存在: $zipPath');
      }

      // 获取模板资源文件目录
      final supportDir = await DirectoryManager.getSupportDirectory();
      final targetDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'templates',
      );

      // 如果目标目录已存在且有内容，先清空（处理旧版本，使用 FileManager）
      final targetFile = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        p.join('templates', '$id'),
      );
      if (await targetFile.exists()) {
        await FileManager.deleteDirectory(targetFile, deleteDirectory: false);
      }

      onProgress?.call(0.2);

      // 解压到目标目录（SupportDirectory/templates）
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: targetDir,
      );

      // 解压后，将目录名 cavals 重命名为 id（templates/{id}）
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
      debugPrint('TemplateDownload: 模板资源文件解压完成: ${targetDir.path}');
    } catch (e) {
      debugPrint('TemplateDownload: 解压模板资源文件失败: $e');
      rethrow;
    }
  }

  /// 保存或更新模板
  /// [model] 中间页模型
  /// 返回 true 表示成功，false 表示失败
  /// 注意：此方法仅保存模板元数据到数据库
  Future<bool> saveOrUpdateTemplate(MiddleModel model) async {
    try {
      // 1. 创建 ManagerModel
      final managerModel = ManagerModel(
        id: model.id,
        timestamp: model.editTime,
      );

      // 2. 保存或更新数据库记录
      final success = await TemplateStore.instance.save(managerModel);
      if (!success) {
        debugPrint('TemplateDownload: 保存数据库记录失败, id=${model.id}');
        return false;
      }
      debugPrint('TemplateDownload: 模板更新或保存成功, id=${model.id}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('TemplateResourceDownload: 保存模板失败: $e\n$stackTrace');
      return false;
    }
  }
}
