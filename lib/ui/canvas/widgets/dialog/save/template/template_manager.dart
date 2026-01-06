import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:voicetemplate/file/index.dart';

/// 模版管理类
class TemplateManager {
  TemplateManager._();
  static TemplateManager? _instance;
  static TemplateManager get instance {
    _instance ??= TemplateManager._();
    return _instance!;
  }

  /// 从「保存模版」来源新增 / 覆盖一个模版资源
  /// [id] 业务侧模版 id
  /// 返回 true 表示成功，false 表示失败
  Future<bool> saveTemplateFromSaveFlow(int id, int timestamp) async {
    if (id == 0) return false;
    try {
      // 1. 源目录：Documents/cavals
      final documentsDir = await DirectoryManager.getDocumentsDirectory();
      final sourceCavalsDir = Directory(p.join(documentsDir.path, 'cavals'));
      if (!await sourceCavalsDir.exists()) {
        debugPrint('TemplateManager:目录不存在，无法保存模版: ${sourceCavalsDir.path}');
        return false;
      }

      // 2. 目标根目录：Application Support/templates
      final supportDir = await DirectoryManager.getSupportDirectory();
      final templatesRootDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'templates',
      );

      // 3. 删除所有以 "<id>_" 开头的旧模版目录
      await _deleteTemplatesByIdPrefix(templatesRootDir, id);

      // 4. 准备新的目标目录名：<id>_<timestamp>
      final newTemplateDirName = '${id}_$timestamp';
      final newTemplateDir = Directory(
        p.join(templatesRootDir.path, newTemplateDirName),
      );

      // 确保目标目录是干净的
      if (await newTemplateDir.exists()) {
        await FileManager.deleteDirectory(
          newTemplateDir,
          deleteDirectory: true,
        );
      }
      await newTemplateDir.create(recursive: true);

      // 5. 递归复制 cavals 目录到新模版目录
      await _copyDirectoryRecursive(sourceCavalsDir, newTemplateDir);

      debugPrint('TemplateManager: 模版已保存到: ${newTemplateDir.path}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('TemplateManager: 保存模版失败: $e\n$stackTrace');
      return false;
    }
  }

  /// 删除指定 id 相关的模版（以 "id_timestamp" 开头的目录）
  Future<void> deleteTemplatesById(int id) async {
    if (id == 0) return;

    try {
      final supportDir = await DirectoryManager.getSupportDirectory();
      final templatesRootDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'templates',
      );

      await _deleteTemplatesByIdPrefix(templatesRootDir, id);
    } catch (e, stackTrace) {
      debugPrint('TemplateManager: 删除模版失败: $e\n$stackTrace');
    }
  }

  /// 在指定的 templates 根目录下，删除所有以 "id_timestamp" 开头的子目录
  Future<void> _deleteTemplatesByIdPrefix(
    Directory templatesRootDir,
    int id,
  ) async {
    if (!await templatesRootDir.exists()) return;

    await for (final entity in templatesRootDir.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! Directory) continue;

      final dirName = p.basename(entity.path);
      if (dirName.startsWith('${id}_')) {
        await FileManager.deleteDirectory(entity, deleteDirectory: true);
        debugPrint('TemplateManager: 已删除旧模版目录: ${entity.path}');
      }
    }
  }

  /// 递归复制目录内容（与 DraftStoreManager 中的逻辑类似）
  Future<void> _copyDirectoryRecursive(
    Directory source,
    Directory destination,
  ) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destination.path, name);

      if (entity is File) {
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        final targetDir = Directory(targetPath);
        await _copyDirectoryRecursive(entity, targetDir);
      }
    }
  }
}
