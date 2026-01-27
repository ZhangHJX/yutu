import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'file_log_manager.dart';

/// 应用日志记录器
/// 提供简单的日志接口，自动拼接时间
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  late Logger? consoleLogger;
  final FileLogManager _fileManager = FileLogManager.instance;
  bool _initialized = false;

  // 日志写入队列
  final _logQueue = <String>[];
  bool _isProcessing = false;
  IOSink? _currentSink;
  File? _currentFile;
  Timer? _processTimer;

  /// 初始化日志系统
  Future<void> init() async {
    if (_initialized) return;

    // 初始化控制台日志（仅在 debug 模式下输出）
    consoleLogger = Logger(
      printer: SimplePrinter(colors: false, printTime: true),
    );

    // 确保日志目录存在
    await _fileManager.getLogDirectory();
    _initialized = true;

    // 启动定时处理任务
    _startBackgroundWriter();
  }

  /// 启动后台写入任务
  void _startBackgroundWriter() {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _processQueue();
    });
  }

  /// 处理日志队列
  Future<void> _processQueue() async {
    if (_isProcessing || _logQueue.isEmpty) return;

    _isProcessing = true;
    try {
      // 获取当前日志文件
      final logFile = await _fileManager.getCurrentLogFile();

      // 如果文件改变了，关闭旧的 sink
      if (_currentFile != null && _currentFile!.path != logFile.path) {
        await _closeCurrentSink();
      }

      // 打开新的 sink（如果需要）
      if (_currentSink == null) {
        _currentFile = logFile;
        _currentSink = logFile.openWrite(mode: FileMode.append);
      }

      // 批量写入队列中的日志（一次最多处理 100 条，避免阻塞太久）
      final logsToWrite = <String>[];
      int count = 0;
      while (_logQueue.isNotEmpty && count < 100) {
        logsToWrite.add(_logQueue.removeAt(0));
        count++;
      }

      if (logsToWrite.isNotEmpty && _currentSink != null) {
        // 一次性写入所有日志，减少 I/O 操作
        _currentSink!.writeAll(logsToWrite, '');
        await _currentSink!.flush();
      }
    } catch (e) {
      // 写入失败，关闭当前 sink 并重试
      await _closeCurrentSink();
      if (kDebugMode) {
        debugPrint('日志写入失败: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 刷新所有待写入的日志（应用关闭时调用）
  Future<void> flush() async {
    // 停止定时器
    _processTimer?.cancel();
    _processTimer = null;

    // 处理完所有剩余的日志
    while (_logQueue.isNotEmpty || _isProcessing) {
      await _processQueue();
      if (_logQueue.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // 关闭 sink
    await _closeCurrentSink();
  }

  /// 关闭当前的 sink
  Future<void> _closeCurrentSink() async {
    if (_currentSink != null) {
      try {
        await _currentSink!.flush();
        await _currentSink!.close();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('关闭日志 sink 失败: $e');
        }
      }
      _currentSink = null;
      _currentFile = null;
    }
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final millisecond = dateTime.millisecond.toString().padLeft(3, '0');
    return '$year-$month-$day $hour:$minute:$second.$millisecond';
  }

  /// 写入日志到文件（添加到队列）
  void _writeToFile(String level, String message) {
    try {
      final timestamp = _formatTimestamp(DateTime.now());
      final logEntry = '[$timestamp] [$level] $message\n';

      // 添加到队列
      _logQueue.add(logEntry);

      // 确保后台任务正在运行
      if (!_isProcessing) {
        _processQueue();
      }
    } catch (e) {
      // 日志写入失败时，尝试输出到控制台
      if (kDebugMode) {
        debugPrint('日志入队失败: $e');
      }
    }
  }

  /// Info 日志
  void i(String message) {
    if (kDebugMode) {
      consoleLogger?.i(message);
    }
    _writeToFile('INFO', message);
  }

  /// Error 日志
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    final errorMessage = error != null
        ? '$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}'
        : message;

    if (kDebugMode) {
      consoleLogger?.e(errorMessage);
    }
    _writeToFile('ERROR', errorMessage);
  }

  static void info(String message) {
    AppLogger.instance.i(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.instance.e(message, [error, stackTrace]);
  }
}
