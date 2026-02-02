import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../core/file_manager/directory_path/index.dart';
import '../../canvas/fonts/font_manager.dart';
import '../../canvas/widgets/property/text_dialog/model/font_info_model.dart';
import 'draft_edit_model.dart';

/// 草稿下载服务
/// 负责下载服务器草稿的字体和压缩包
class DraftDownloadService {
  DraftDownloadService._();
  static final DraftDownloadService instance = DraftDownloadService._();

  /// 准备服务器草稿（下载字体和草稿压缩包）
  ///
  /// [editModel] 服务器草稿模型
  /// [onProgress] 进度回调，0.0-1.0
  Future<void> prepareServerDraft(
    DraftEditModel editModel, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      onProgress?.call(0.0);

      // 1. 下载缺失的字体（0-60%）
      await _downloadMissingFonts(
        editModel.frontData,
        onProgress: (progress) {
          onProgress?.call(progress * 0.6); // 0-60%
        },
      );

      onProgress?.call(0.6);

      // 2. 下载并解压草稿压缩包（60-100%）
      await _downloadAndExtractDraft(
        editModel.recourcesUrl,
        onProgress: (progress) {
          onProgress?.call(0.6 + progress * 0.4); // 60-100%
        },
      );

      onProgress?.call(1.0);
    } catch (e, stackTrace) {
      AppLogger.error('DraftDownloadService准备服务器草稿失败', e, stackTrace);
      rethrow;
    }
  }

  /// 下载缺失的字体
  Future<void> _downloadMissingFonts(
    List<DraftEditItemModel> frontData, {
    ValueChanged<double>? onProgress,
  }) async {
    if (frontData.isEmpty) {
      onProgress?.call(1.0);
      return;
    }

    // 过滤掉无效的字体数据
    final validFonts = frontData
        .where((item) => item.frontId != 0 && item.frontVersion.isNotEmpty)
        .toList();

    if (validFonts.isEmpty) {
      onProgress?.call(1.0);
      return;
    }

    // 获取字体信息列表
    final fontInfoList = await _getFontInfoList(
      validFonts.map((e) => e.frontId).toList(),
    );

    if (fontInfoList.isEmpty) {
      AppLogger.info('DraftDownloadService: 未获取到字体信息');
      onProgress?.call(1.0);
      return;
    }

    // 检查并下载缺失的字体
    final totalFonts = fontInfoList.length;
    for (int i = 0; i < fontInfoList.length; i++) {
      final fontInfo = fontInfoList[i];

      try {
        // FontManager 会自动检查本地是否已下载，如果已下载则跳过
        await FontManager.to.prepareFontByInfo(fontInfo);
        AppLogger.info(
          'DraftDownloadService: 字体 ${fontInfo.id} 准备完成 (${i + 1}/$totalFonts)',
        );
      } catch (e) {
        AppLogger.error('DraftDownloadService: 字体 ${fontInfo.id} 下载失败', e);
        // 单个字体失败不影响整体流程，继续下载其他字体
      }

      // 更新进度
      onProgress?.call((i + 1) / totalFonts);
    }
  }

  /// 根据 frontId 列表获取字体信息
  Future<List<FontInfoModel>> _getFontInfoList(List<int> frontIds) async {
    try {
      // 获取所有字体列表
      final result = await http.post(
        '/front/index',
        converter: listConverter(FontInfoModel.fromJson),
      );

      if (result.code == 0 && result.data != null) {
        final allFonts = result.data as List<FontInfoModel>;
        // 过滤出需要的字体
        return allFonts.where((font) => frontIds.contains(font.id)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('DraftDownloadService: 获取字体信息失败:', e);
      return [];
    }
  }

  /// 下载并解压草稿压缩包
  Future<void> _downloadAndExtractDraft(
    String resourcesUrl, {
    ValueChanged<double>? onProgress,
  }) async {
    if (resourcesUrl.isEmpty) {
      throw Exception('DraftDownloadService: 草稿资源URL为空');
    }

    // 1. 创建临时下载目录
    final tempDir = await DirectoryManager.getTempSubDirectory(
      'draft_download',
    );
    final zipFilePath = p.join(tempDir.path, 'draft.zip');

    try {
      // 2. 下载压缩包
      onProgress?.call(0.1);
      await _downloadZipFile(resourcesUrl, zipFilePath, (progress) {
        onProgress?.call(0.1 + progress * 0.3); // 10-40%
      });

      onProgress?.call(0.4);

      // 3. 解压到草稿目录
      await _extractDraftZip(zipFilePath, (progress) {
        onProgress?.call(0.4 + progress * 0.6); // 40-100%
      });

      onProgress?.call(1.0);
    } finally {
      // 清理临时文件
      try {
        final zipFile = File(zipFilePath);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      } catch (e) {
        AppLogger.error('DraftDownloadService: 清理临时文件失败:', e);
      }
    }
  }

  /// 下载压缩包文件
  Future<void> _downloadZipFile(
    String url,
    String savePath,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final taskId = 'draft_${DateTime.now().millisecondsSinceEpoch}';
      final task = DownloadTask(
        url: url,
        filename: 'draft.zip',
        baseDirectory: BaseDirectory.temporary,
        directory: 'draft_download',
        updates: Updates.statusAndProgress,
        taskId: taskId,
      );

      final targetPath = await task.filePath();
      final targetFile = File(targetPath);

      // 如果文件已存在，先删除
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final downloader = FileDownloader();
      final result = await downloader.download(
        task,
        onProgress: (progress) {
          onProgress?.call(progress.clamp(0.0, 1.0));
        },
      );

      if (result.status != TaskStatus.complete) {
        throw Exception(
          'DraftDownloadService: 下载失败: ${result.status}, ${result.exception}',
        );
      }

      // 将下载的文件移动到目标路径
      if (targetPath != savePath) {
        final downloadedFile = File(targetPath);
        if (await downloadedFile.exists()) {
          await downloadedFile.copy(savePath);
          await downloadedFile.delete();
        }
      }

      AppLogger.info('DraftDownloadService: 压缩包下载完成: $savePath');
    } catch (e) {
      AppLogger.error('DraftDownloadService: 下载压缩包失败', e);
      rethrow;
    }
  }

  /// 解压草稿压缩包到草稿目录
  Future<void> _extractDraftZip(
    String zipPath,
    ValueChanged<double>? onProgress,
  ) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('DraftDownloadService: 压缩包文件不存在: $zipPath');
      }

      // 获取草稿目录
      final draftDir = await DirectoryManager.getDocumentsDirectory();

      // 清空草稿目录（删除旧草稿）
      if (await draftDir.exists()) {
        await FileManager.deleteDirectory(draftDir, deleteDirectory: false);
      }
      await draftDir.create(recursive: true);

      onProgress?.call(0.2);

      // 解压到草稿目录
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: draftDir,
      );

      onProgress?.call(1.0);
      AppLogger.info('DraftDownloadService: 压缩包解压完成: ${draftDir.path}');
    } catch (e) {
      AppLogger.error('DraftDownloadService: 解压压缩包失败', e);
      rethrow;
    }
  }
}
