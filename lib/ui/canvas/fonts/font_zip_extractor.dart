import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:common/common.dart';
import 'font_file_parser.dart';
import 'font_models.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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
    required int fontId,
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
      fontId: fontId,
      version: version,
      url: url,
    );

    // ✅ 后台 isolate 做扫描/解析/建 meta（避免卡 UI）
    return Isolate.run(() => _parseInIsolate(parseParams));
  }

  /// isolate entry：只做纯 Dart 的 IO/解析/组装
  static Future<FontInstallResult> _parseInIsolate(
    _FontParseParams params,
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
        final meta = await FontFileParser.parseFontFile(
          file: file,
          rootDir: rootDir,
        );
        if (meta != null) {
          parsedWeights.add(meta);
        }
      } catch (e) {
        // isolate 内 debugPrint 可用，但别太频繁
        debugPrint('FontZipExtractor parse error: $e');
      }
    }

    if (parsedWeights.isEmpty) {
      throw Exception(
        'FontZipExtractor: all font files failed to parse in ${params.installDir}',
      );
    }

    final weights = _dedupeAndSortWeights(parsedWeights);
    final displayFamilyName = _pickDisplayFamilyName(weights);

    final familyMeta = FontFamilyMeta(
      fontId: params.fontId,
      version: params.version,
      displayFamilyName: displayFamilyName,
      url: params.url,
      weights: weights,
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

  /// 去重 + 排序（同字重保留第一个）
  /// 注意：这里假设 FontWeightMeta 有 int weight 字段（你项目里若字段名不同，改一下这里即可）
  static List<FontWeightMeta> _dedupeAndSortWeights(
    List<FontWeightMeta> input,
  ) {
    final map = <int, FontWeightMeta>{};
    for (final item in input) {
      final int w = item.weight; // 若你的字段叫 fontWeight / usWeightClass，改这里
      map.putIfAbsent(w, () => item);
    }

    final list = map.values.toList();
    list.sort((a, b) => a.weight.compareTo(b.weight));
    return list;
  }

  /// 选择一个更稳定的 displayFamilyName：
  /// - 取出现次数最多的 familyName（不同文件 familyName 不一致时更鲁棒）
  static String _pickDisplayFamilyName(List<FontWeightMeta> weights) {
    final counts = <String, int>{};

    for (final w in weights) {
      final name = w.familyName.trim();
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return weights.first.familyName;
    }

    String best = counts.keys.first;
    int bestCount = counts[best] ?? 0;

    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }

    return best;
  }
}
