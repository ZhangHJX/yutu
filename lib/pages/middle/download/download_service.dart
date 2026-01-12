import 'package:flutter/foundation.dart';
import '../model/middle_model.dart';
import 'font_download.dart';
import 'draft_download.dart';
import 'template_download.dart';

/// 下载服务管理类
/// 负责协调字体和资源文件的下载
/// 区分草稿和模板两种场景
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  /// 字体下载服务
  final FontDownload _font = FontDownload.instance;

  /// 草稿资源下载服务
  final DraftDownload _draft = DraftDownload.instance;

  /// 模板资源下载服务
  final TemplateDownload _template = TemplateDownload.instance;

  /// 检查字体文件是否存在且版本匹配
  Future<bool> checkFontExists(int fontId, String requiredVersion) async {
    return await _font.checkFontExists(fontId, requiredVersion);
  }

  /// 下载单个字体文件
  /// 如果字体不存在或版本不匹配，则下载新版本
  /// 下载完成后，删除旧版本，移动新版本到字体文件夹
  Future<void> downloadFontIfNeeded(
    FontItemModel fontItem, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _font.downloadFontIfNeeded(
      fontItem,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 下载所有需要的字体（并发下载）
  Future<void> downloadFontsIfNeeded(
    List<FontItemModel> frontData, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _font.downloadFontsIfNeeded(
      frontData,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 取消所有正在进行的字体下载
  Future<void> cancelAllFontDownloads() async {
    return await _font.cancelAllFontDownloads();
  }

  /// 检查草稿资源文件是否存在
  /// 返回 (是否存在, 时间戳是否匹配)
  Future<(bool exists, bool timestampMatches)> checkDraftResourceExists(
    int id,
    int editTime,
  ) async {
    return await _draft.checkDraftResourceExists(id, editTime);
  }

  /// 下载草稿资源文件
  /// 如果数据库中有数据且时间戳匹配，直接使用本地文件
  /// 否则下载并解压到 sqflite_draft/{id}
  /// 返回资源文件路径
  Future<String> downloadDraftResource(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _draft.downloadDraftResource(
      resourcesUrl,
      id,
      editTime,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 下载模板资源文件
  /// 如果文件已存在，跳过下载
  /// 否则下载并解压到 templates/{id}
  /// 返回资源文件路径
  Future<String> downloadTemplateResource(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _template.downloadTemplateResource(
      resourcesUrl,
      id,
      editTime,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 检查模板资源文件是否存在
  /// 返回 (是否存在, 时间戳是否匹配)
  Future<(bool exists, bool timestampMatches)> checkTemplateResourceExists(
    int id,
    int editTime,
  ) async {
    return await _template.checkTemplateResourceExists(id, editTime);
  }

  /// 取消所有正在进行的下载（字体和资源）
  Future<void> cancelAllDownloads() async {
    await _font.cancelAllFontDownloads();
    await cancelResourceDownload();
  }

  /// 取消当前正在进行的资源文件下载
  /// 同时取消草稿和模板的下载任务
  Future<void> cancelResourceDownload() async {
    await _draft.cancelResourceDownload();
    await _template.cancelResourceDownload();
  }

  /// 将资源文件复制到 Documents/cavals 目录
  /// 将 sourcePath 目录的内容直接复制到 Documents/cavals
  /// 注意：sourcePath 目录的内容就是 cavals 的内容（zip 解压后的内容）
  Future<void> copyResourceToCavals(String sourcePath, bool isDraft) async {
    if (isDraft) {
      return await _draft.copyResourceToCavals(sourcePath);
    } else {
      return await _template.copyResourceToCavals(sourcePath);
    }
  }
}
