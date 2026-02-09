import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_archive/flutter_archive.dart';
import 'file_log_manager.dart';

/// 日志上报器
/// 负责将日志文件打包为 zip 或直接上传
class LogUploader {
  LogUploader._();
  static final LogUploader instance = LogUploader._();
  final FileLogManager _fileManager = FileLogManager.instance;

  /// 将日志文件打包为 zip
  /// 返回 zip 文件路径，如果失败返回 null
  Future<String?> packLogsToZip() async {
    try {
      final sourceDir = await _fileManager.getLogDirectory();

      // 创建临时目录存放 zip 文件
      final tempDir = await Directory.systemTemp.createTemp('logs_zip_');
      final zipPath = p.join(
        tempDir.path,
        'logs_${DateTime.now().millisecondsSinceEpoch}.zip',
      );

      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      // 打包日志文件
      await ZipFile.createFromDirectory(
        sourceDir: sourceDir,
        zipFile: zipFile,
        recurseSubDirs: true,
        includeBaseDirectory: true,
      );
      return zipPath;
    } catch (e) {
      return null;
    }
  }
}
