import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'file_rotator.dart';

/// 应用日志管理器
/// 提供 info 和 error 级别的日志记录功能
/// - Debug 模式：输出到控制台
/// - Release 模式：写入到文件（SupportDirectory）
class AppLogger {
  AppLogger._internal();

  static AppLogger? _instance;
  static AppLogger get instance {
    _instance ??= AppLogger._internal();
    return _instance!;
  }

  Logger? _logger;
  File? _logFile;
  Directory? _logDirectory;
  bool _initialized = false;

  /// 初始化日志系统
  /// 必须在首次使用前调用
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      // 获取 SupportDirectory
      final supportDir = await getApplicationSupportDirectory();
      _logDirectory = Directory(p.join(supportDir.path, 'logs'));

      // 确保日志目录存在
      if (!await _logDirectory!.exists()) {
        await _logDirectory!.create(recursive: true);
      }

      // 获取日志文件路径
      final logFilePath = await FileRotator.getOrCreateCurrentLogFile(
        _logDirectory!,
      );
      _logFile = File(logFilePath);

      // 在 release 模式下，写入前检查并执行轮转
      if (!kDebugMode) {
        await FileRotator.rotateIfNeeded(_logDirectory!, logFilePath);
      }

      // 根据模式配置 Logger
      if (kDebugMode) {
        // Debug 模式：输出到控制台
        // _logger = Logger(
        //   printer: PrettyPrinter(
        //     methodCount: 0, // 不显示方法调用栈
        //     errorMethodCount: 3, // 错误时显示3层调用栈
        //     lineLength: 120,
        //     colors: true,
        //     printEmojis: true,
        //     dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        //   ),
        //   output: ConsoleOutput(),
        //   filter: _CustomLogFilter(),
        // );

        _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 3,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
          output: MultiOutput([
            ConsoleOutput(),
            _RotatingFileOutput(file: _logFile!, logDirectory: _logDirectory!),
          ]),
          filter: _CustomLogFilter(),
        );
      } else {
        // Release 模式：写入到文件
        _logger = Logger(
          printer: _SimpleFilePrinter(),
          output: _RotatingFileOutput(
            file: _logFile!,
            logDirectory: _logDirectory!,
          ),
          filter: _CustomLogFilter(),
        );
      }

      _initialized = true;
    } catch (e) {
      // 初始化失败时，降级到控制台输出
      _logger = Logger(printer: PrettyPrinter(), output: ConsoleOutput());
      _initialized = true;
    }
  }

  /// 记录 info 级别日志
  /// [message] 日志消息，时间戳会自动添加
  /// 性能优化：快速返回，不阻塞调用线程
  void info(String message) {
    if (!_initialized) {
      // 如果未初始化，异步初始化（不阻塞）
      initialize()
          .then((_) {
            _logInfo(message);
          })
          .catchError((e) {
            // 初始化失败，静默处理
          });
      return;
    }
    // 直接调用，Logger内部会异步处理
    _logInfo(message);
  }

  /// 记录 error 级别日志
  /// [message] 日志消息，时间戳会自动添加
  /// [error] 可选的错误对象
  /// [stackTrace] 可选的堆栈跟踪
  /// 性能优化：快速返回，不阻塞调用线程
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      // 如果未初始化，异步初始化（不阻塞）
      initialize()
          .then((_) {
            _logError(message, error: error, stackTrace: stackTrace);
          })
          .catchError((e) {
            // 初始化失败，静默处理
          });
      return;
    }
    // 直接调用，Logger内部会异步处理
    _logError(message, error: error, stackTrace: stackTrace);
  }

  /// 获取日志文件路径
  /// 返回当前日志文件的完整路径
  String? getLogPath() {
    return _logFile?.path;
  }

  /// 获取日志目录路径
  /// 返回日志目录的完整路径
  String? getLogDirectoryPath() {
    return _logDirectory?.path;
  }

  /// 内部方法：记录 info 日志
  void _logInfo(String message) {
    final timestampedMessage = _formatMessage(message);
    _logger?.i(timestampedMessage);
  }

  /// 内部方法：记录 error 日志
  void _logError(String message, {Object? error, StackTrace? stackTrace}) {
    final timestampedMessage = _formatMessage(message);
    _logger?.e(timestampedMessage, error: error, stackTrace: stackTrace);
  }

  /// 格式化消息，添加时间戳
  /// 格式：[YYYY-MM-DD HH:mm:ss] message
  /// 优化：使用StringBuffer和预格式化提高性能
  String _formatMessage(String message) {
    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.write('[');
    // 使用预格式化的年月日，减少字符串操作
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    buffer.write(year);
    buffer.write('-');
    buffer.write(month);
    buffer.write('-');
    buffer.write(day);
    buffer.write(' ');
    buffer.write(hour);
    buffer.write(':');
    buffer.write(minute);
    buffer.write(':');
    buffer.write(second);
    buffer.write('] ');
    buffer.write(message);
    return buffer.toString();
  }
}

/// 自定义日志过滤器
/// 只允许 info 和 error 级别
class _CustomLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level == Level.info || event.level == Level.error;
  }
}

/// 简单的文件打印机
/// 用于 release 模式，输出简洁的日志格式
class _SimpleFilePrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final level = event.level.toString().split('.').last.toUpperCase();
    final message = event.message;

    if (event.error != null) {
      return ['[$level] $message\nError: ${event.error}'];
    }

    return ['[$level] $message'];
  }
}

/// 带轮转功能的文件输出
/// 在每次写入前检查文件大小，必要时执行轮转
/// 性能优化：减少检查频率，使用快速检查，异步处理轮转
class _RotatingFileOutput extends LogOutput {
  final Directory _logDirectory;
  File _currentFile;
  AdvancedFileOutput _fileOutput;
  DateTime _lastCheckTime = DateTime.now();
  bool _isRotating = false; // 防止并发轮转
  static const Duration _checkInterval = Duration(
    seconds: 30,
  ); // 每30秒检查一次（性能优化）
  static const Duration _quickCheckInterval = Duration(seconds: 10); // 快速检查间隔

  _RotatingFileOutput({required File file, required Directory logDirectory})
    : _currentFile = file,
      _logDirectory = logDirectory,
      _fileOutput = AdvancedFileOutput(path: file.path);

  @override
  void output(OutputEvent event) {
    // 先输出日志，不阻塞（性能优化：日志写入优先）
    _fileOutput.output(event);

    // 异步检查轮转，不阻塞日志写入
    _checkAndRotateAsync();
  }

  /// 异步检查并执行轮转（不阻塞主线程）
  void _checkAndRotateAsync() {
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(_lastCheckTime);

    // 如果正在轮转，跳过检查
    if (_isRotating) {
      return;
    }

    // 快速检查：只检查当前文件大小（轻量级）
    if (timeSinceLastCheck > _quickCheckInterval) {
      // 保存当前时间差，避免在异步回调中使用过时的值
      final savedTimeSinceLastCheck = timeSinceLastCheck;
      FileRotator.shouldRotateQuick(_currentFile.path)
          .then((quickCheckResult) {
            // 重新检查时间差，确保在回调时仍然满足条件
            final currentTime = DateTime.now();
            final currentTimeSinceLastCheck = currentTime.difference(
              _lastCheckTime,
            );
            if (quickCheckResult &&
                currentTimeSinceLastCheck > _checkInterval) {
              // 快速检查通过且到了完整检查时间，执行完整检查
              _performFullCheck();
            }
          })
          .catchError((e) {
            // 快速检查失败，忽略
          });
    }
  }

  /// 执行完整的轮转检查
  void _performFullCheck() {
    if (_isRotating) {
      return;
    }

    _isRotating = true;
    FileRotator.shouldRotate(_logDirectory)
        .then((needsRotation) {
          _lastCheckTime = DateTime.now();

          if (needsRotation) {
            // 需要轮转，异步执行（不阻塞）
            FileRotator.rotateIfNeeded(_logDirectory, _currentFile.path)
                .then((newFilePath) {
                  _updateFileOutput(newFilePath);
                  _isRotating = false;
                })
                .catchError((e) {
                  // 轮转失败，继续使用当前文件
                  _isRotating = false;
                });
          } else {
            _isRotating = false;
          }
        })
        .catchError((e) {
          // 检查失败，忽略
          _isRotating = false;
        });
  }

  /// 更新文件输出引用（轮转后文件路径可能改变）
  void _updateFileOutput(String newFilePath) {
    if (newFilePath != _currentFile.path) {
      // 文件路径已改变，重新创建 AdvancedFileOutput
      // 注意：destroy 是异步的，但这里不等待，因为新文件输出会立即接管
      _fileOutput.destroy().catchError((e) {
        // 销毁失败不影响新文件输出
      });
      _currentFile = File(newFilePath);
      _fileOutput = AdvancedFileOutput(path: newFilePath);
    }
  }

  @override
  Future<void> destroy() async {
    await _fileOutput.destroy();
  }
}
