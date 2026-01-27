import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 日志文件管理器
/// 负责管理日志文件的创建、切分、大小控制
class FileLogManager {
  FileLogManager._();
  static final FileLogManager instance = FileLogManager._();

  static const int maxFileCount = 5; // 最大文件数量
  static const int maxTotalSize = 5 * 1024 * 1024; // 5MB
  static const String logDirName = 'logs';

  Directory? _logDirectory;
  File? _currentLogFile;
  DateTime? _currentFileCreateTime;

  /// 获取日志目录
  Future<Directory> _getLogDirectory() async {
    if (_logDirectory != null) return _logDirectory!;
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory(p.join(supportDir.path, logDirName));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    _logDirectory = logDir;
    return logDir;
  }

  /// 生成日志文件名（格式：年月日时分秒.log）
  String _generateLogFileName(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year$month$day$hour$minute$second.log';
  }

  /// 获取当前日志文件
  Future<File> _getCurrentLogFile() async {
    final now = DateTime.now();

    // 如果当前文件存在，检查是否可以继续使用
    if (_currentLogFile != null && _currentFileCreateTime != null) {
      try {
        // 检查文件是否存在
        if (await _currentLogFile!.exists()) {
          final stat = await _currentLogFile!.stat();
          // 如果文件大小未超过单个文件限制（总大小/文件数），继续使用
          if (stat.size < maxTotalSize ~/ maxFileCount) {
            return _currentLogFile!;
          }
        }
      } catch (e) {
        // 文件不存在或无法访问，需要查找或创建新文件
      }
    }

    // 当前文件不存在或已超过限制，尝试查找最新的日志文件进行复用
    final logDir = await _getLogDirectory();
    final latestFile = await _findLatestLogFile(logDir);

    if (latestFile != null) {
      // 找到最新文件，检查是否可以复用
      try {
        final stat = await latestFile.stat();
        // 如果文件大小未超过单个文件限制，复用该文件
        if (stat.size < maxTotalSize ~/ maxFileCount) {
          _currentLogFile = latestFile;
          // 从文件名解析创建时间（文件名格式：YYYYMMDDHHmmss.log）
          _currentFileCreateTime = _parseFileNameToDateTime(latestFile.path);
          return latestFile;
        }
      } catch (e) {
        // 文件无法访问，继续创建新文件
      }
    }

    // 需要创建新文件（使用当前时间戳作为文件名）
    await _cleanOldLogs();
    final fileName = _generateLogFileName(now);
    final logFile = File(p.join(logDir.path, fileName));
    _currentLogFile = logFile;
    _currentFileCreateTime = now;
    return logFile;
  }

  /// 查找最新的日志文件
  Future<File?> _findLatestLogFile(Directory logDir) async {
    try {
      if (!await logDir.exists()) {
        return null;
      }

      final files = await logDir.list().toList();
      final logFiles = <File>[];

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.log')) {
          logFiles.add(entity);
        }
      }

      if (logFiles.isEmpty) {
        return null;
      }

      // 按文件名（时间戳）排序，最新的在前
      logFiles.sort((a, b) => b.path.compareTo(a.path));

      // 返回最新的文件
      return logFiles.first;
    } catch (e) {
      return null;
    }
  }

  /// 从文件名解析日期时间（文件名格式：YYYYMMDDHHmmss.log）
  DateTime? _parseFileNameToDateTime(String filePath) {
    try {
      final fileName = p.basename(filePath);
      // 移除 .log 后缀
      final timeStr = fileName.replaceAll('.log', '');

      if (timeStr.length != 14) {
        return null;
      }

      final year = int.parse(timeStr.substring(0, 4));
      final month = int.parse(timeStr.substring(4, 6));
      final day = int.parse(timeStr.substring(6, 8));
      final hour = int.parse(timeStr.substring(8, 10));
      final minute = int.parse(timeStr.substring(10, 12));
      final second = int.parse(timeStr.substring(12, 14));

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      return null;
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs() async {
    try {
      final logDir = await _getLogDirectory();
      final files = await logDir.list().toList();

      // 过滤出日志文件并按修改时间排序
      final logFiles = <File>[];
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.log')) {
          logFiles.add(entity);
        }
      }

      // 按文件名（时间戳）排序，最新的在前
      logFiles.sort((a, b) => b.path.compareTo(a.path));

      // 计算总大小
      int totalSize = 0;
      for (var file in logFiles) {
        try {
          final stat = await file.stat();
          totalSize += stat.size;
        } catch (e) {
          // 忽略无法访问的文件
        }
      }

      // 如果文件数量超过限制或总大小超过限制，删除最旧的文件
      while ((logFiles.length >= maxFileCount || totalSize >= maxTotalSize) &&
          logFiles.isNotEmpty) {
        final oldestFile = logFiles.removeLast();
        try {
          final stat = await oldestFile.stat();
          totalSize -= stat.size;
          await oldestFile.delete();
        } catch (e) {
          // 忽略删除失败的文件
        }
      }
    } catch (e) {
      // 清理失败不影响日志写入
    }
  }

  /// 获取当前日志文件（供外部使用）
  Future<File> getCurrentLogFile() async {
    return await _getCurrentLogFile();
  }

  /// 获取日志目录
  Future<Directory> getLogDirectory() async {
    return await _getLogDirectory();
  }
}
