import 'package:flutter/foundation.dart';
import '../../canvas/fonts/font_manager.dart';
import '../../canvas/fonts/font_meta_store.dart';
import '../model/middle_model.dart';

/// 字体下载服务
/// 负责下载和管理字体文件
class FontDownload {
  FontDownload._();
  static final FontDownload instance = FontDownload._();

  /// 当前正在下载的字体任务ID映射：fontId -> taskId
  final Map<int, String> _currentFontTaskIds = {};

  /// 检查字体文件是否存在且版本匹配
  Future<bool> checkFontExists(int fontId, String requiredVersion) async {
    final localMeta = await FontMetaStore.instance.readMeta(fontId);
    if (localMeta == null) {
      return false;
    }
    return localMeta.version == requiredVersion;
  }

  /// 下载字体文件
  /// 如果字体不存在或版本不匹配，则下载新版本
  /// 下载完成后，删除旧版本，移动新版本到字体文件夹
  Future<void> downloadFontIfNeeded(
    FontItemModel fontItem, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final fontId = fontItem.frontId;
    final requiredVersion = fontItem.frontVersion;
    final fontUrl = fontItem.frontUrl;

    // 检查字体是否已存在且版本匹配
    final exists = await checkFontExists(fontId, requiredVersion);
    if (exists) {
      debugPrint(
        'FontDownloadService: 字体 $fontId 版本 $requiredVersion 已存在，跳过下载',
      );
      onProgress?.call(1.0);
      return;
    }

    debugPrint('FontDownloadService: 开始下载字体 $fontId 版本 $requiredVersion');

    // 生成任务ID用于取消
    final taskId = 'font_${fontId}_${DateTime.now().millisecondsSinceEpoch}';
    _currentFontTaskIds[fontId] = taskId;

    try {
      // 检查是否应该取消
      if (shouldCancel != null && shouldCancel()) {
        _currentFontTaskIds.remove(fontId);
        throw Exception('下载已取消');
      }

      // 使用 FontManager 下载字体（会自动处理版本检查和旧版本删除）
      try {
        await FontManager.to.prepareFont(
          fontId: fontId,
          version: requiredVersion,
          url: fontUrl,
          onProgress: (progress) {
            // 在进度回调中检查是否应该取消
            if (shouldCancel != null && shouldCancel()) {
              // 抛出异常以停止下载流程
              throw Exception('下载已取消');
            }
            onProgress?.call(progress);
          },
        );
      } catch (e) {
        // 如果是取消操作，重新抛出
        if (e.toString().contains('取消')) {
          rethrow;
        }
        // 其他错误也重新抛出
        rethrow;
      }

      _currentFontTaskIds.remove(fontId);
      debugPrint('FontDownloadService: 字体 $fontId 下载完成');
    } catch (e) {
      _currentFontTaskIds.remove(fontId);
      debugPrint('FontDownloadService: 字体 $fontId 下载失败: $e');
      rethrow;
    }
  }

  /// 取消所有正在进行的字体下载
  /// 注意：由于无法直接获取 FontDownloadManager 的任务ID，
  /// 实际的取消通过 shouldCancel 标志和抛出异常来实现
  Future<void> cancelAllFontDownloads() async {
    debugPrint('FontDownloadService: 取消所有字体下载');
    _currentFontTaskIds.clear();
  }

  /// 下载所有需要的字体（并发下载）
  Future<void> downloadFontsIfNeeded(
    List<FontItemModel> frontData, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (frontData.isEmpty) {
      onProgress?.call(1.0);
      return;
    }

    // 检查是否应该取消
    if (shouldCancel != null && shouldCancel()) {
      debugPrint('FontDownloadService: 字体下载已取消');
      throw Exception('下载已取消');
    }

    final totalFonts = frontData.length;

    // 用于跟踪每个字体的下载进度
    final Map<int, double> fontProgressMap = {};
    for (int i = 0; i < frontData.length; i++) {
      fontProgressMap[i] = 0.0;
    }

    // 更新总进度的辅助函数
    void updateTotalProgress() {
      double totalProgress = 0.0;
      for (final progress in fontProgressMap.values) {
        totalProgress += progress;
      }
      final averageProgress = totalProgress / totalFonts;
      onProgress?.call(averageProgress);
    }

    // 创建所有下载任务（并发执行）
    final List<Future<void>> downloadTasks = [];

    for (int i = 0; i < frontData.length; i++) {
      final fontItem = frontData[i];
      final taskIndex = i;

      // 创建下载任务（不立即 await）
      final task =
          downloadFontIfNeeded(
            fontItem,
            onProgress: (progress) {
              // 更新该字体的进度
              fontProgressMap[taskIndex] = progress;
              // 更新总进度
              updateTotalProgress();
            },
            shouldCancel: shouldCancel,
          ).catchError((e) {
            // 如果是取消操作，直接抛出
            if (e.toString().contains('取消')) {
              throw e;
            }
            debugPrint('FontDownloadService: 字体 ${fontItem.frontId} 下载失败: $e');
            // 单个字体失败不影响整体流程，标记为完成
            fontProgressMap[taskIndex] = 1.0;
            updateTotalProgress();
            return null;
          });

      downloadTasks.add(task);
    }

    // 等待所有下载任务完成（并发执行）
    try {
      await Future.wait(downloadTasks);
      onProgress?.call(1.0);
    } catch (e) {
      // 如果是取消操作，直接抛出
      if (e.toString().contains('取消')) {
        rethrow;
      }
      // 其他错误也抛出
      rethrow;
    }
  }
}
