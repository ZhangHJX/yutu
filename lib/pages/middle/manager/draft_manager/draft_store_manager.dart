import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../canvas/model/index.dart';
import '../../../../file/index.dart';
import 'draft_store.dart';
import '../manager_model.dart';
import 'package:common/common.dart';

/// 草稿存储管理类
/// 负责：
/// 1. 传入 CanvasModel，根据 uuid 判断草稿是否保存过
/// 2. 如果不存在，就保存起来，如果有保存过就进行数据的更新
/// 3. 同时将 Documents 目录下的 cavals 文件 copy 到 Application Support 下的 sqflite_draft，文件名使用 uuid
class DraftStoreManager {
  DraftStoreManager._();
  static DraftStoreManager? _instance;
  static DraftStoreManager get instance {
    _instance ??= DraftStoreManager._();
    return _instance!;
  }

  /// 保存或更新草稿
  /// [canvasModel] 画布模型
  /// 返回 true 表示成功，false 表示失败
  Future<bool> saveOrUpdateDraft(CanvasModel canvasModel, int id) async {
    try {
      // 1. 创建 DraftModel（不再保存画布 JSON 数据）
      final draftModel = ManagerModel(
        id: id,
        timestamp: canvasModel.timestamp > 0
            ? canvasModel.timestamp
            : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      // 2. 保存或更新数据库记录
      final success = await DraftStore.instance.save(draftModel);
      if (!success) {
        AppLogger.info('DraftStoreManager: 保存数据库记录失败, id=${canvasModel.id}');
        return false;
      }

      // 3. 复制 Documents/cavals 目录到 Application Support/sqflite_draft/{id}
      await _copyCavalsDirectory(id);

      AppLogger.info(
        'DraftStoreManager: 草稿更新或保存成功, id=${canvasModel.id}, uuid=${canvasModel.uuid}',
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('DraftStoreManager: 保存草稿失败:', e, stackTrace);
      return false;
    }
  }

  /// 复制 Documents/cavals 目录到 Application Support/sqflite_draft/{id}
  /// [id] 画布的 id，作为目标目录名
  Future<void> _copyCavalsDirectory(int id) async {
    try {
      // 获取源目录：Documents/cavals
      final documentsDir = await DirectoryManager.getDocumentsDirectory();
      final sourceCavalsDir = Directory(p.join(documentsDir.path, 'cavals'));

      // 检查源目录是否存在
      if (!await sourceCavalsDir.exists()) {
        AppLogger.info(
          'DraftStoreManager: 源目录不存在，跳过文件复制: ${sourceCavalsDir.path}',
        );
        return;
      }

      // 获取目标目录：Application Support/sqflite_draft/{uuid}
      final supportDir = await DirectoryManager.getSupportDirectory();
      final targetDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        p.join('sqflite_draft', '$id'),
      );

      // 如果目标目录已存在，先删除（确保是最新的内容）
      if (await targetDir.exists()) {
        await FileManager.deleteDirectory(targetDir, deleteDirectory: true);
      }

      // 创建目标目录
      await targetDir.create(recursive: true);

      // 递归复制目录内容
      await _copyDirectoryRecursive(sourceCavalsDir, targetDir);

      AppLogger.info('DraftStoreManager: cavals 目录已复制到: ${targetDir.path}');
    } catch (e, stackTrace) {
      AppLogger.error('DraftStoreManager: 复制 cavals 目录失败:', e, stackTrace);
      // 不抛出异常，文件复制失败不影响数据库保存
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

  /// 根据 id 删除草稿（包括数据库记录和文件）
  /// 返回 true 表示删除成功，false 表示删除失败
  Future<bool> deleteDraftById(int id) async {
    try {
      if (id == 0) {
        return false;
      }
      // 1. 删除数据库记录
      final dbSuccess = await DraftStore.instance.deleteById(id);
      // 2. 删除文件目录
      try {
        final supportDir = await DirectoryManager.getSupportDirectory();
        final draftDir = Directory(
          p.join(supportDir.path, 'sqflite_draft', '$id'),
        );
        if (await draftDir.exists()) {
          await FileManager.deleteDirectory(draftDir, deleteDirectory: true);
          AppLogger.info('DraftStoreManager: 草稿文件目录已删除: ${draftDir.path}');
        }
      } catch (e) {
        AppLogger.error('DraftStoreManager: 删除草稿文件目录失败:', e);
        // 文件删除失败不影响返回结果
      }
      if (dbSuccess) {
        AppLogger.info('DraftStoreManager: 草稿已删除, id=$id');
      }
      return dbSuccess;
    } catch (e, stackTrace) {
      AppLogger.error('DraftStoreManager: 删除草稿失败:', e, stackTrace);
      return false;
    }
  }

  /// 获取草稿对应的 cavals 目录路径
  /// 根据 Application Support/sqflite_draft/{uuid} 目录，
  /// 将文件拷贝到 Documents 目录下，并命名为 cavals，
  /// 返回拷贝后的 Documents/cavals 目录路径
  Future<String?> getDraftCavalsPath(int id) async {
    try {
      if (id == 0) {
        return null;
      }

      // 源目录：Application Support/sqflite_draft/{uuid}
      final supportDir = await DirectoryManager.getSupportDirectory();
      final draftDir = Directory(
        p.join(supportDir.path, 'sqflite_draft', '$id'),
      );

      if (!await draftDir.exists()) {
        AppLogger.info('DraftStoreManager: 源草稿目录不存在: ${draftDir.path}');
        return null;
      }

      // 目标目录：Documents/cavals
      final documentsDir = await DirectoryManager.getDocumentsDirectory();
      final targetCavalsDir = Directory(p.join(documentsDir.path, 'cavals'));

      // 如果目标 cavals 目录已存在，先删除，保证是当前 uuid 的内容
      if (await targetCavalsDir.exists()) {
        await FileManager.deleteDirectory(
          targetCavalsDir,
          deleteDirectory: true,
        );
      }

      // 将 sqflite_draft/{uuid} 下的内容复制到 Documents/cavals
      await _copyDirectoryRecursive(draftDir, targetCavalsDir);

      AppLogger.info(
        'DraftStoreManager: 草稿文件已从 $id 恢复到 Documents/cavals: ${targetCavalsDir.path}',
      );

      return targetCavalsDir.path;
    } catch (e) {
      AppLogger.error('DraftStoreManager: 拷贝草稿 cavals 目录失败:', e);
      return null;
    }
  }

  /// 清空所有草稿（包括数据库记录和对应的文件目录）
  /// 返回 true 表示数据库清空成功，false 表示数据库清空失败
  /// 文件删除失败不会影响返回结果
  Future<bool> clearAllDrafts() async {
    try {
      // 1. 清空数据库记录
      final dbSuccess = await DraftStore.instance.clearAll();

      // 2. 删除所有草稿文件目录（保留数据库文件）
      try {
        final supportDir = await DirectoryManager.getSupportDirectory();
        final draftRootDir = Directory(
          p.join(supportDir.path, 'sqflite_draft'),
        );

        if (await draftRootDir.exists()) {
          await for (final entity in draftRootDir.list(recursive: false)) {
            if (entity is Directory) {
              await FileManager.deleteDirectory(entity, deleteDirectory: true);
            } else if (entity is File) {
              final name = p.basename(entity.path);
              // 保留数据库文件，其余清理掉
              if (name != 'drafts.db') {
                await entity.delete();
              }
            }
          }
          AppLogger.info('DraftStoreManager: 所有草稿文件目录已清空');
        }
      } catch (e) {
        AppLogger.error('DraftStoreManager: 清空草稿文件目录失败:', e);
        // 文件删除失败不影响整体返回结果
      }

      if (dbSuccess) {
        AppLogger.info('DraftStoreManager: 所有草稿已清空');
      }
      return dbSuccess;
    } catch (e, stackTrace) {
      AppLogger.error('DraftStoreManager: 清空所有草稿失败:', e, stackTrace);
      return false;
    }
  }
}
