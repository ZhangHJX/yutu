import 'package:flutter/foundation.dart';
import '../model/middle_model.dart';
import 'font_download_service.dart';
import 'resource_download_service.dart';

/// 模板下载服务
/// 负责协调字体和资源文件的下载
/// 区分草稿和模板两种场景
class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  /// 字体下载服务
  final FontDownloadService _fontService = FontDownloadService.instance;

  /// 资源文件下载服务
  final ResourceDownloadService _resourceService =
      ResourceDownloadService.instance;

  /// 检查字体文件是否存在且版本匹配
  Future<bool> checkFontExists(int fontId, String requiredVersion) async {
    return await _fontService.checkFontExists(fontId, requiredVersion);
  }

  /// 下载字体文件
  /// 如果字体不存在或版本不匹配，则下载新版本
  /// 下载完成后，删除旧版本，移动新版本到字体文件夹
  Future<void> downloadFontIfNeeded(
    FontItemModel fontItem, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _fontService.downloadFontIfNeeded(
      fontItem,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 取消所有正在进行的字体下载
  Future<void> cancelAllFontDownloads() async {
    return await _fontService.cancelAllFontDownloads();
  }

  /// 下载所有需要的字体（并发下载）
  Future<void> downloadFontsIfNeeded(
    List<FontItemModel> frontData, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _fontService.downloadFontsIfNeeded(
      frontData,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 检查草稿资源文件是否存在
  /// 返回 (是否存在, 时间戳是否匹配)
  Future<(bool exists, bool timestampMatches)> checkDraftResourceExists(
    int id,
    int editTime,
  ) async {
    return await _resourceService.checkDraftResourceExists(id, editTime);
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
    return await _resourceService.downloadDraftResource(
      resourcesUrl,
      id,
      editTime,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 下载模板资源文件
  /// 如果文件已存在，跳过下载
  /// 否则下载并解压到 templates/{id}_editTime
  /// 返回资源文件路径
  Future<String> downloadTemplateResource(
    String resourcesUrl,
    int id,
    int editTime, {
    ValueChanged<double>? onProgress,
    bool Function()? shouldCancel,
  }) async {
    return await _resourceService.downloadTemplateResource(
      resourcesUrl,
      id,
      editTime,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  /// 检查模板资源文件是否存在（解压后是目录）
  Future<bool> checkTemplateResourceExists(int id, int editTime) async {
    return await _resourceService.checkTemplateResourceExists(id, editTime);
  }

  /// 取消当前正在进行的资源文件下载
  Future<void> cancelResourceDownload() async {
    return await _resourceService.cancelResourceDownload();
  }

  /// 取消所有正在进行的下载（字体和资源）
  Future<void> cancelAllDownloads() async {
    await _fontService.cancelAllFontDownloads();
    await _resourceService.cancelResourceDownload();
  }

  /// 将资源文件复制到 Documents/cavals 目录
  /// 将 sourcePath 目录的内容直接复制到 Documents/cavals
  /// 注意：sourcePath 目录的内容就是 cavals 的内容（zip 解压后的内容）
  Future<void> copyResourceToCavals(String sourcePath) async {
    return await _resourceService.copyResourceToCavals(sourcePath);
  }
}
