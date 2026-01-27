import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:common/common.dart';
import 'ttf_metadata_plus.dart';
import 'font_models.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import '../widgets/property/text_dialog/model/font_info_model.dart';

/// Isolate 入参（只做“扫描 + 解析 + 组 meta”）
/// 注意：不要把 File/Directory 之类复杂对象跨 isolate 传递，传路径字符串即可。
class _FontParseParams {
  final String installDir;
  final int fontId;
  final String version;
  final String url;

  const _FontParseParams({
    required this.installDir,
    required this.fontId,
    required this.version,
    required this.url,
  });
}

/// 最终返回
class FontInstallResult {
  final FontFamilyMeta meta;
  final String installDir;

  const FontInstallResult({required this.meta, required this.installDir});
}

/// 负责：
/// - 主 isolate：解压 zip 到临时目录（flutter_archive 走 platform channel）
/// - 后台 isolate：扫描 ttf/otf + 调用 FontFileParser 解析 + 生成 FontFamilyMeta
class FontZipExtractor {
  /// 推荐：解压在主 isolate，解析在后台 isolate（更稳）
  static Future<FontInstallResult> extractAndParse({
    required String zipPath,
    required String tempInstallDir,
    required FontInfoModel info,
    required String version,
    required String url,
  }) async {
    final zipFile = File(zipPath);
    final outDir = Directory(tempInstallDir);

    await _recreateDirectory(outDir);

    try {
      // ✅ 主 isolate 调用 platform channel（最稳）
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: outDir,
      );

      /// ✅ 解压成功后先清理
      await cleanupExtractArtifacts(outDir);
    } catch (_) {
      // 解压失败要清理，避免下次扫到“半安装”目录
      await _safeDeleteDirectory(outDir);
      rethrow;
    }

    final parseParams = _FontParseParams(
      installDir: outDir.path,
      fontId: info.id,
      version: version,
      url: url,
    );

    // ✅ 后台 isolate 做扫描/解析/建 meta（避免卡 UI）
    return Isolate.run(() => _parseInIsolate(parseParams, info));
  }

  /// isolate entry：只做纯 Dart 的 IO/解析/组装
  static Future<FontInstallResult> _parseInIsolate(
    _FontParseParams params,
    FontInfoModel info,
  ) async {
    final rootDir = Directory(params.installDir);
    if (!await rootDir.exists()) {
      throw Exception(
        'FontZipExtractor: install dir not exists: ${params.installDir}',
      );
    }

    final fontFiles = await _scanFontFiles(rootDir);
    if (fontFiles.isEmpty) {
      throw Exception(
        'FontZipExtractor: no .ttf/.otf found in ${params.installDir}',
      );
    }

    final parsedWeights = <FontWeightMeta>[];
    for (final file in fontFiles) {
      // 单个文件失败不要影响整体
      try {
        final meta = await TTfMetadataPlus.fromFile(file.path);
        final relativePath = p.relative(file.path, from: rootDir.path);

        // ✅ 生成 familyKey：优先使用 postScriptName，否则从文件名生成
        final familyKey =
            meta.postScriptName ??
            _generateFamilyKeyFromPath(
              relativePath,
              params.fontId,
              params.version,
            );

        final weightMeta = FontWeightMeta(
          relativePath: relativePath,
          familyKey: familyKey,
          styleName: meta.styleName ?? "系统默认",
          weight: meta.weight,
        );
        parsedWeights.add(weightMeta);
      } catch (e) {
        // isolate 内 debugPrint 可用，但别太频繁
        AppLogger.error('FontZipExtractor parse error:', e);
      }
    }

    if (parsedWeights.isEmpty) {
      throw Exception(
        'FontZipExtractor: all font files failed to parse in ${params.installDir}',
      );
    }

    final familyMeta = FontFamilyMeta(
      fontId: params.fontId,
      version: params.version,
      fontName: info.name,
      fontImage: info.image,
      downloadUrl: info.url,
      weights: parsedWeights,
    );

    return FontInstallResult(meta: familyMeta, installDir: params.installDir);
  }

  static Future<void> _recreateDirectory(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  static Future<void> _safeDeleteDirectory(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // ignore
    }
  }

  static Future<List<File>> _scanFontFiles(Directory rootDir) async {
    final results = <File>[];
    await for (final entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;

      final path = entity.path.toLowerCase();
      if (!path.endsWith('.ttf') && !path.endsWith('.otf')) continue;

      // 可选：过滤 0 字节文件（坏包/解压异常时常见）
      try {
        final stat = await entity.stat();
        if (stat.size <= 0) continue;
      } catch (_) {
        continue;
      }

      results.add(entity);
    }
    return results;
  }

  /// 从文件路径生成唯一的 familyKey（当 postScriptName 不可用时）
  static String _generateFamilyKeyFromPath(
    String relativePath,
    int fontId,
    String version,
  ) {
    // 从文件名提取（去掉扩展名）
    final fileName = p.basenameWithoutExtension(relativePath);
    // 清理文件名，只保留字母、数字、连字符
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '-');
    // 生成唯一标识：font_{fontId}_v{version}_{sanitizedFileName}
    return 'font_${fontId}_v${version}_$sanitized';
  }

  /// 清除本地解压后的垃圾文件
  static Future<void> cleanupExtractArtifacts(Directory rootDir) async {
    if (!await rootDir.exists()) return;

    final directoriesToDelete = <Directory>[];

    await for (final entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      final fullPath = entity.path;
      final baseName = p.basename(fullPath);
      final baseLower = baseName.toLowerCase();

      // 目录：__MACOSX
      if (entity is Directory && baseLower == '__macosx') {
        directoriesToDelete.add(entity);
        continue;
      }

      if (entity is! File) continue;

      // 文件：macOS + Windows 常见垃圾
      final isDsStore = baseName == '.DS_Store';
      final isAppleDouble = baseName.startsWith('._'); // AppleDouble
      final isThumbsDb = baseLower == 'thumbs.db';

      // 防御：路径任意层级包含 __MACOSX（安卓也适用）
      final isInsideMacosx = p
          .split(fullPath)
          .any((seg) => seg.toLowerCase() == '__macosx');

      if (isDsStore || isAppleDouble || isThumbsDb || isInsideMacosx) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }

    // 删除 __MACOSX 目录
    for (final dir in directoriesToDelete) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }
}
