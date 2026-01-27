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

  /// 上传日志文件（需要外部实现上传逻辑）
  /// [uploadCallback] 接收 zip 文件路径，返回是否上传成功
  Future<bool> uploadLogs({
    required Future<bool> Function(String zipPath) uploadCallback,
  }) async {
    try {
      final zipPath = await packLogsToZip();
      if (zipPath == null) {
        return false;
      }
      final success = await uploadCallback(zipPath);

      // 上传成功后删除临时 zip 文件
      if (success) {
        try {
          await File(zipPath).delete();
        } catch (e) {
          // 忽略删除失败
        }
      }

      return success;
    } catch (e) {
      return false;
    }
  }
}
