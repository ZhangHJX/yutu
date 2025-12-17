import 'dart:isolate';
import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';

import 'font_file_parser.dart';
import 'font_models.dart';

/// Isolate 入参
class _FontInstallParams {
  final String zipPath;
  final String tempInstallDir;
  final int fontId;
  final int version;
  final String url;

  const _FontInstallParams({
    required this.zipPath,
    required this.tempInstallDir,
    required this.fontId,
    required this.version,
    required this.url,
  });
}

/// Isolate 出参
class FontInstallResult {
  final FontFamilyMeta meta;
  final String installDir;

  const FontInstallResult({required this.meta, required this.installDir});
}

/// 负责：
/// - 解压 zip 到临时目录
/// - 扫描 ttf/otf 文件
/// - 调用 [FontFileParser] 解析 name / OS/2
/// - 返回 FontFamilyMeta
class FontZipExtractor {
  /// 在 Isolate 中执行完整的“解压+解析”流程
  static Future<FontInstallResult> extractAndParse({
    required String zipPath,
    required String tempInstallDir,
    required int fontId,
    required int version,
    required String url,
  }) async {
    final params = _FontInstallParams(
      zipPath: zipPath,
      tempInstallDir: tempInstallDir,
      fontId: fontId,
      version: version,
      url: url,
    );
    return Isolate.run(() => _isolateEntry(params));
  }

  static Future<FontInstallResult> _isolateEntry(
    _FontInstallParams params,
  ) async {
    final zipFile = File(params.zipPath);
    final outDir = Directory(params.tempInstallDir);
    if (await outDir.exists()) {
      await outDir.delete(recursive: true);
    }
    await outDir.create(recursive: true);

    // 解压：使用 flutter_archive
    await ZipFile.extractToDirectory(zipFile: zipFile, destinationDir: outDir);

    // 扫描 ttf/otf
    final fontFiles = <File>[];
    await for (final ent in outDir.list(recursive: true)) {
      if (ent is! File) continue;
      final lower = ent.path.toLowerCase();
      if (lower.endsWith('.ttf') || lower.endsWith('.otf')) {
        fontFiles.add(ent);
      }
    }

    if (fontFiles.isEmpty) {
      throw Exception('FontZipExtractor: no ttf/otf found in zip');
    }

    final weights = <FontWeightMeta>[];
    for (final f in fontFiles) {
      try {
        final meta = await FontFileParser.parseFontFile(
          file: f,
          rootDir: outDir,
        );
        if (meta != null) {
          weights.add(meta);
        }
      } catch (e) {
        debugPrint('FontZipExtractor parse error: $e');
      }
    }

    if (weights.isEmpty) {
      throw Exception('FontZipExtractor: all font files failed to parse');
    }

    // 取第一个字重的 familyName 作为 displayFamilyName
    final displayFamilyName = weights.first.familyName;

    final family = FontFamilyMeta(
      fontId: params.fontId,
      version: params.version,
      displayFamilyName: displayFamilyName,
      url: params.url,
      weights: weights,
    );

    return FontInstallResult(meta: family, installDir: outDir.path);
  }
}
