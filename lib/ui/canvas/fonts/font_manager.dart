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
  RxList<FontFamilyMeta> recommendedFonts = <FontFamilyMeta>[].obs;

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

  /// 是否正在执行“温和后台更新”
  bool _isWarmUpdating = false;

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
      // markUsed(fontId);
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

      // markUsed(fontId);
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

  /// 温和后台更新：只更新“本地已安装且有新版本”的字体
  ///
  /// - 仅当 [fontStatus] 为 ready 时才尝试更新
  /// - 通过比对本地 meta.version 和接口返回的 version 判断是否有更新
  /// - 串行执行，避免并发爆流量，也避免频繁触发 FontLoader
  /// - 无状态下载：不更新 fontStatus、allFonts，不触发 UI 响应式更新
  Future<void> warmUpdateInstalledFonts(List<FontInfoModel> remoteFonts) async {
    // 避免重复进入同一个后台更新流程
    if (_isWarmUpdating) return;

    _isWarmUpdating = true;
    try {
      for (final info in remoteFonts) {
        final status = fontStatus[info.id];
        if (status != FontStatus.ready) {
          // 只更新“本地已安装”的字体
          continue;
        }

        final localMeta = allFonts[info.id];
        if (localMeta == null) continue;

        // 没有新版本则跳过
        if (localMeta.version == info.version) {
          continue;
        }

        debugPrint(
          'FontManager: warm update fontId=${info.id}, '
          'localVersion=${localMeta.version}, remoteVersion=${info.version}',
        );

        try {
          // 使用静默安装方法，不触发 UI 更新
          await _prepareFontSilent(
            fontId: info.id,
            version: info.version,
            url: info.url,
          );
        } catch (e) {
          debugPrint(
            'FontManager: warm update failed for fontId=${info.id}, error=$e',
          );
        }
      }
    } finally {
      _isWarmUpdating = false;
    }
  }

  /// 静默安装字体（用于后台更新，不触发 UI 状态更新）
  ///
  /// - 不更新 fontStatus（避免触发 UI 响应式更新）
  /// - 静默更新 allFonts（直接赋值，不触发响应式更新，但数据会是最新的）
  /// - 不调用 markUsed（避免触发推荐列表更新）
  /// - 不加入 _installingTasks（避免被 UI 检测到）
  /// - 静默下载、安装、注册字体
  Future<FontFamilyMeta> _prepareFontSilent({
    required int fontId,
    required String version,
    required String url,
  }) async {
    // 1. 如果本地已有且版本一致，直接返回（静默，不更新状态）
    final localMeta = await FontMetaStore.instance.readMeta(fontId);
    if (localMeta != null && localMeta.version == version) {
      return localMeta;
    }

    // 2. 静默下载 zip（不更新 fontStatus）
    final zipFile = await FontDownloadManager.instance.downloadFontZip(
      fontId: fontId,
      url: url,
      onProgress: (_) {}, // 静默，不报告进度
    );

    // 3. 解压到临时安装目录
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

    // 4. 原子替换到最终目录
    final targetDir = await FontMetaStore.instance.fontDir(fontId);
    Directory? backup;
    try {
      if (await targetDir.exists()) {
        backup = Directory('${targetDir.path}_backup');
        if (await backup.exists()) {
          await backup.delete(recursive: true);
        }
        await targetDir.rename(backup.path);
      }

      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }

      final sourceDir = Directory(result.installDir);
      await sourceDir.rename(targetDir.path);

      // 5. 写 meta.json
      await FontMetaStore.instance.writeMeta(result.meta);

      // 6. 静默更新 allFonts（直接赋值，不触发响应式更新）
      // 注意：在 GetX 中，直接赋值 allFonts[fontId] = newMeta 不会触发响应式更新
      // 但数据会是最新的，下次 UI 读取时会拿到新数据
      allFonts[fontId] = result.meta;

      // 7. 使用内部 familyKey + FontLoader 注册到 Flutter 引擎（静默）
      await _registerFontFamily(result.meta);

      // 安装成功后清理备份目录
      if (backup != null && await backup.exists()) {
        try {
          await backup.delete(recursive: true);
        } catch (e) {
          debugPrint('FontManager cleanup backup error: $e');
        }
      }
      return result.meta;
    } catch (e) {
      debugPrint('FontManager silent install error: $e');
      // 回滚：恢复旧目录
      if (backup != null && await backup.exists()) {
        if (await targetDir.exists()) {
          await targetDir.delete(recursive: true);
        }
        await backup.rename(targetDir.path);
      }
      rethrow;
    } finally {
      // 清理临时目录
      if (await installTmpDir.exists()) {
        await installTmpDir.delete(recursive: true);
      }
      // 清理下载的 zip 文件
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

  /// 记录“最近使用”，用于推荐字体
  void markUsed(int fontId) {
    debugPrint('markUsed====$_recentUsed recommendedFonts=$recommendedFonts');
    if (!_recentUsed.contains(fontId)) {
      _recentUsed.add(fontId);
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

  /// 使用 FontWeightMeta 中的 familyKey 单独注册每个字体文件到 Flutter 引擎
  /// - 每个字体文件使用自己的 familyKey（通常是 postScriptName）单独注册
  /// - 这样可以精确匹配每个字体文件，避免 weight 冲突问题
  Future<void> _registerFontFamily(FontFamilyMeta meta) async {
    final dir = await FontMetaStore.instance.fontDir(meta.fontId);

    var registeredCount = 0;
    for (final weightMeta in meta.weights) {
      // 使用每个文件自己的 familyKey
      final familyKey = weightMeta.familyKey;

      if (familyKey.isEmpty) {
        debugPrint(
          'FontManager: familyKey is empty for path=${weightMeta.relativePath}',
        );
        continue;
      }

      // 如果已注册过，跳过
      if (_registeredFamilyKeys.contains(familyKey)) {
        continue;
      }

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
        final loader = FontLoader(familyKey);
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await loader.load();

        _registeredFamilyKeys.add(familyKey);
        registeredCount++;
        debugPrint(
          'FontManager: registered familyKey=$familyKey for fontId=${meta.fontId}',
        );
      } catch (e) {
        debugPrint(
          'FontManager: failed to register familyKey=$familyKey for fontId=${meta.fontId}, path=$filePath, error=$e',
        );
      }
    }

    if (registeredCount == 0) {
      debugPrint(
        'FontManager: no valid font files to register for fontId=${meta.fontId}',
      );
    } else {
      debugPrint(
        'FontManager: registered $registeredCount font files for fontId=${meta.fontId}',
      );
    }
  }
}
