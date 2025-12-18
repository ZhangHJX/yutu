import 'dart:io';

import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../file/index.dart';
import '../widgets/property/text_dialog/model/font_info_model.dart';
import 'font_download_manager.dart';
import 'font_meta_store.dart';
import 'font_models.dart';
import 'font_zip_extractor.dart';

/// 字体领域层入口：统一管理字体下载 / 安装 / 状态
///
/// 使用方式（示例伪代码）：
/// - 模板进入：调用 [prepareFontByInfo]，等待成功后再把 fontFamily/weight 写入 element
/// - 自定义编辑：默认使用 'AlibabaPuHuiTi-Regular.otf'（未下载则走 prepare 逻辑）
class FontManager extends GetxController {
  static FontManager get to => Get.find<FontManager>();

  /// 所有字体状态：fontId -> FontStatus
  final RxMap<int, FontStatus> fontStatus = <int, FontStatus>{}.obs;

  /// 所有已知字体 meta：fontId -> FontFamilyMeta
  final RxMap<int, FontFamilyMeta> allFonts = <int, FontFamilyMeta>{}.obs;

  /// 推荐字体（模板字体 + 最近使用）
  final RxList<FontFamilyMeta> recommendedFonts = <FontFamilyMeta>[].obs;

  /// fontId -> 正在进行的“安装”任务（下载 + 解压 + 解析 + 落盘）
  final Map<int, Future<FontFamilyMeta>> _installingTasks = {};

  /// 最近使用的字体 id（用于推荐）
  final List<int> _recentUsed = [];

  /// 模板已使用的字体 id（用于推荐优先展示）
  final List<int> _templateUsed = [];

  /// 已经通过 FontLoader 注册过的 familyKey，避免重复 load
  final Set<String> _registeredFamilyKeys = <String>{};

  /// 判断是否有有值
  bool get isInstallingTasks => _installingTasks.isNotEmpty;

  /// 初始化：扫描本地已安装字体
  Future<void> initFromDisk() async {
    final installed = await FontMetaStore.instance.scanAllInstalled();
    for (final meta in installed) {
      allFonts[meta.fontId] = meta;
      fontStatus[meta.fontId] = FontStatus.ready;
      // 启动时自动把本地已安装字体注册到 Flutter 引擎
      await _registerFontFamily(meta);
    }
  }

  /// 对外主入口：根据接口返回的 FontInfoModel 准备字体
  ///
  /// - 如果已 ready：直接返回 meta
  /// - 如果需要下载：走完整安装流程
  Future<FontFamilyMeta> prepareFontByInfo(
    FontInfoModel info, {
    ValueChanged<double>? onProgress,
  }) {
    return prepareFont(
      fontId: info.id,
      version: info.version,
      url: info.url,
      onProgress: onProgress,
    );
  }

  /// 准备/安装字体（原子提交）
  Future<FontFamilyMeta> prepareFont({
    required int fontId,
    required String version,
    required String url,
    ValueChanged<double>? onProgress,
  }) {
    // 单 fontId “单飞”：同一时间只有一个安装任务
    final existing = _installingTasks[fontId];
    if (existing != null) return existing;

    final task = _prepareFontInternal(
      fontId: fontId,
      version: version,
      url: url,
      onProgress: onProgress,
    );
    _installingTasks[fontId] = task;
    task.whenComplete(() {
      _installingTasks.remove(fontId);
    });
    return task;
  }

  Future<FontFamilyMeta> _prepareFontInternal({
    required int fontId,
    required String version,
    required String url,
    ValueChanged<double>? onProgress,
  }) async {
    // 1. 如果本地已有且版本一致，直接返回
    final localMeta = await FontMetaStore.instance.readMeta(fontId);
    if (localMeta != null && localMeta.version == version) {
      allFonts[fontId] = localMeta;
      fontStatus[fontId] = FontStatus.ready;
      _markUsed(fontId);
      return localMeta;
    }

    fontStatus[fontId] = FontStatus.downloading;

    // 2. 下载 zip
    final zipFile = await FontDownloadManager.instance.downloadFontZip(
      fontId: fontId,
      url: url,
      onProgress: (p) {
        onProgress?.call(p * 0.7); // 0~70% 下载进度
      },
    );

    fontStatus[fontId] = FontStatus.installing;

    // 3. 解压到临时安装目录  ../tmp/fonts_install/fontId/
    final installTmpDir = await DirectoryManager.getTempSubDirectory(
      'fonts_install/$fontId',
    );

    final result = await FontZipExtractor.extractAndParse(
      zipPath: zipFile.path,
      tempInstallDir: installTmpDir.path,
      fontId: fontId,
      version: version,
      url: url,
    );

    onProgress?.call(0.85); // 解压+解析完成

    // 4. 原子替换到最终目录 ApplicationSupportDirectory/fonts/fontId
    final targetDir = await FontMetaStore.instance.fontDir(fontId);
    debugPrint('原子替换到最终目录 $targetDir');
    Directory? backup;
    try {
      /// 生成一个备份目录路径：
      if (await targetDir.exists()) {
        backup = Directory('${targetDir.path}_backup');
        if (await backup.exists()) {
          await backup.delete(recursive: true);
        }

        /// 把现有的 targetDir 重命名/移动到备份路径
        await targetDir.rename(backup.path);
      }

      // 将临时目录 rename 过去   targetDir 仍然存在。此时你直接 delete(recursive: true) 会把旧字体目录彻底删掉
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }

      final sourceDir = Directory(result.installDir);
      await sourceDir.rename(targetDir.path);

      // 5. 写 meta.json
      await FontMetaStore.instance.writeMeta(result.meta);

      allFonts[fontId] = result.meta;
      fontStatus[fontId] = FontStatus.ready;

      // 6. 使用内部 familyKey + FontLoader 注册到 Flutter 引擎
      await _registerFontFamily(result.meta);

      _markUsed(fontId);
      onProgress?.call(1.0);

      // 安装成功后清理备份目录，避免磁盘占用和干扰后续安装
      if (backup != null && await backup.exists()) {
        try {
          await backup.delete(recursive: true);
        } catch (e) {
          debugPrint('FontManager cleanup backup error: $e');
        }
      }
      return result.meta;
    } catch (e) {
      debugPrint('FontManager install error: $e');
      // 回滚：恢复旧目录
      if (backup != null && await backup.exists()) {
        if (await targetDir.exists()) {
          await targetDir.delete(recursive: true);
        }
        await backup.rename(targetDir.path);
      }
      fontStatus[fontId] = FontStatus.failed;
      rethrow;
    } finally {
      // 清理临时目录
      if (await installTmpDir.exists()) {
        await installTmpDir.delete(recursive: true);
      }
      // 清理下载的 zip 文件，避免临时文件堆积
      if (await zipFile.exists()) {
        try {
          await zipFile.delete();
        } catch (e) {
          debugPrint('FontManager delete zip error: $e');
        }
      }
    }
  }

  /// UI：获取某个字体可用字重（下拉框用）
  List<FontWeightMeta> getWeights(int fontId) {
    final meta = allFonts[fontId];
    if (meta == null) return const [];
    return meta.weights;
  }

  /// UI：获取默认字重（正常是 Regular / 400）
  FontWeightMeta? getDefaultWeight(int fontId) {
    final meta = allFonts[fontId];
    if (meta == null) return null;
    //找 weight 400，最后兜底第一个
    return meta.weights.firstWhere(
      (w) => w.weight == 400,
      orElse: () {
        return meta.weights.first;
      },
    );
  }

  /// 记录“最近使用”，用于推荐字体
  void _markUsed(int fontId) {
    _recentUsed.remove(fontId);
    _recentUsed.insert(0, fontId);
    if (_recentUsed.length > 20) {
      _recentUsed.removeRange(20, _recentUsed.length);
    }
    _rebuildRecommended();
  }

  /// 根据最近使用 + 已安装构建推荐字体
  void _rebuildRecommended() {
    final list = <FontFamilyMeta>[];
    final seen = <int>{};

    // 模板已用字体优先
    for (final id in _templateUsed) {
      if (!seen.add(id)) continue;
      final meta = allFonts[id];
      if (meta != null) {
        list.add(meta);
      }
    }

    // 最近使用的字体追加
    for (final id in _recentUsed) {
      if (!seen.add(id)) continue;
      final meta = allFonts[id];
      if (meta != null) {
        list.add(meta);
      }
    }
    recommendedFonts.assignAll(list);
  }

  /// 提供模板中已使用的字体列表（用于推荐列表兜底）
  void setTemplateUsedFonts(Iterable<int> fontIds) {
    _templateUsed
      ..clear()
      ..addAll({
        for (final id in fontIds) id, // 保留传入顺序去重
      });
    _rebuildRecommended();
  }

  /// 使用内部 familyKey 注册字体到 Flutter 引擎
  ///
  /// - 不依赖 ttf/otf 内部的 familyName
  /// - 一个 familyKey 下可能有多个字重文件，全部用 FontLoader 加载
  Future<void> _registerFontFamily(FontFamilyMeta meta) async {
    // 已注册过的 familyKey 不再重复 load，避免性能浪费和潜在异常
    if (_registeredFamilyKeys.contains(meta.familyKey)) {
      return;
    }

    final dir = await FontMetaStore.instance.fontDir(meta.fontId);
    final loader = FontLoader(meta.familyKey);

    var addedCount = 0;
    for (final weightMeta in meta.weights) {
      final filePath = p.join(dir.path, weightMeta.relativePath);
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint(
          'FontManager: font file missing for fontId=${meta.fontId}, path=$filePath',
        );
        continue;
      }

      try {
        final bytes = await file.readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        addedCount++;
      } catch (e) {
        debugPrint(
          'FontManager: failed to load font file for fontId=${meta.fontId}, path=$filePath, error=$e',
        );
      }
    }

    if (addedCount == 0) {
      debugPrint(
        'FontManager: no valid font files to register for fontId=${meta.fontId}, familyKey=${meta.familyKey}',
      );
      return;
    }

    try {
      await loader.load();
      _registeredFamilyKeys.add(meta.familyKey);
      debugPrint(
        'FontManager: registered familyKey=${meta.familyKey} with $addedCount font files',
      );
    } catch (e) {
      debugPrint(
        'FontManager: FontLoader.load failed for familyKey=${meta.familyKey}, error=$e',
      );
    }
  }
}
