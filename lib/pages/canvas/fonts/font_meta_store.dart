import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../file/index.dart';
import 'font_models.dart';
import 'package:common/common.dart';

/// 负责读写本地的字体 meta.json，并做简单缓存
/// 目录规范：
/// - 最终安装目录：ApplicationSupportDirectory/fonts/fontId/
/// - 其中 meta.json 存放 FontMetaFile
class FontMetaStore {
  FontMetaStore._();

  static final FontMetaStore instance = FontMetaStore._();

  /// 内存缓存：fontId -> meta
  final Map<int, FontFamilyMeta> _cache = {};

  Directory? _baseDir;

  /// ApplicationSupportDirectory/
  Future<Directory> _ensureBaseDir() async {
    if (_baseDir != null) return _baseDir!;
    final fontsDir = await DirectoryManager.getSupportSubDirectory('fonts');
    _baseDir = fontsDir;
    return fontsDir;
  }

  /// 单个字体最终目录：.../fonts/fontId
  Future<Directory> fontDir(int fontId) async {
    final base = await _ensureBaseDir();
    return await DirectoryManager.getOrCreateSubDirectory(base, '$fontId');
  }

  /// 读取本地 meta.json（如果存在）
  Future<FontFamilyMeta?> readMeta(int fontId) async {
    if (_cache.containsKey(fontId)) {
      return _cache[fontId];
    }
    final dir = await fontDir(fontId);
    try {
      final content = await FileManager.readTextFile(
        directory: dir,
        fileName: 'meta.json',
      );
      if (content == null) return null;
      final familyMeta = FontFamilyMeta.decode(content);
      _cache[fontId] = familyMeta;
      return familyMeta;
    } catch (e) {
      AppLogger.error('FontMetaStore readMeta error:', e);
      return null;
    }
  }

  /// 写入 meta.json（覆盖）
  Future<void> writeMeta(FontFamilyMeta meta) async {
    _cache[meta.fontId] = meta;
    final dir = await fontDir(meta.fontId);
    await FileManager.writeTextFile(
      directory: dir,
      fileName: 'meta.json',
      content: meta.encode(),
    );
  }

  /// 删除某个字体的本地数据（用于回滚）
  Future<void> deleteFont(int fontId) async {
    _cache.remove(fontId);
    final dir = await fontDir(fontId);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (e) {
        AppLogger.error('FontMetaStore deleteFont error:', e);
      }
    }
  }

  /// 扫描本地已安装字体（用于启动时快速恢复）
  Future<List<FontFamilyMeta>> scanAllInstalled() async {
    final base = await _ensureBaseDir();
    final result = <FontFamilyMeta>[];
    if (!await base.exists()) return result;

    await for (final entity in base.list()) {
      if (entity is! Directory) continue;
      final id = int.tryParse(p.basename(entity.path));
      if (id == null) continue;
      final meta = await readMeta(id);
      if (meta != null) {
        result.add(meta);
      }
    }
    return result;
  }
}
