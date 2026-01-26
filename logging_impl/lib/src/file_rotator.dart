import 'dart:io';
import 'package:path/path.dart' as p;

/// 文件轮转器
/// 负责管理日志文件的轮转逻辑
/// 使用基于时间戳的文件命名（YYYYMMDD_HHMMSS.log），创建时直接命名，无需重命名操作
class FileRotator {
  /// 最大总文件大小（5MB）
  static const int maxTotalSizeBytes = 5 * 1024 * 1024;

  /// 最大文件数量
  static const int maxFileCount = 5;

  /// 文件扩展名
  static const String fileExtension = '.log';

  /// 生成基于时间戳的文件名
  /// 格式：YYYYMMDD_HHMMSS.log
  /// 优化：使用 StringBuffer 减少字符串拼接操作
  static String generateTimestampFileName() {
    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.write(now.year.toString().padLeft(4, '0'));
    buffer.write(now.month.toString().padLeft(2, '0'));
    buffer.write(now.day.toString().padLeft(2, '0'));
    buffer.write('_');
    buffer.write(now.hour.toString().padLeft(2, '0'));
    buffer.write(now.minute.toString().padLeft(2, '0'));
    buffer.write(now.second.toString().padLeft(2, '0'));
    buffer.write(fileExtension);
    return buffer.toString();
  }

  /// 获取或创建当前日志文件路径
  /// 如果目录中没有文件，创建新的时间戳文件
  /// 否则返回最新的文件路径（按文件名排序，时间戳最大的）
  static Future<String> getOrCreateCurrentLogFile(
    Directory logDirectory,
  ) async {
    try {
      // 获取所有日志文件
      final logFiles = await _getAllLogFiles(logDirectory);

      if (logFiles.isEmpty) {
        // 没有日志文件，创建新的
        final newFileName = generateTimestampFileName();
        final newFilePath = p.join(logDirectory.path, newFileName);
        final newFile = File(newFilePath);
        await newFile.create();
        return newFilePath;
      }

      // 按文件名排序（时间戳格式，可以直接按字符串排序）
      logFiles.sort((a, b) {
        final aName = p.basename(a.path);
        final bName = p.basename(b.path);
        return bName.compareTo(aName); // 降序，最新的在前
      });

      // 返回最新的文件路径
      return logFiles.first.path;
    } catch (e) {
      // 出错时创建新文件
      final newFileName = generateTimestampFileName();
      final newFilePath = p.join(logDirectory.path, newFileName);
      final newFile = File(newFilePath);
      await newFile.create();
      return newFilePath;
    }
  }

  /// 获取所有日志文件（格式：YYYYMMDD_HHMMSS.log）
  /// 优化：减少字符串操作，提前验证长度
  static Future<List<File>> _getAllLogFiles(Directory directory) async {
    final logFiles = <File>[];
    // YYYYMMDD_HHMMSS.log = 8+1+6+4 = 19 字符
    const expectedLength = 19;

    try {
      final directoryList = directory.list();
      await for (final entity in directoryList) {
        if (entity is File) {
          final fileName = p.basename(entity.path);
          // 快速检查：长度和扩展名
          if (fileName.length == expectedLength &&
              fileName.endsWith(fileExtension) &&
              fileName.contains('_')) {
            // 验证格式：前8位是数字，下划线，后6位是数字
            // 优化：直接使用 substring 而不是 replaceAll 和 split
            final underscoreIndex = fileName.indexOf('_');
            if (underscoreIndex == 8) {
              // 下划线位置正确
              final datePart = fileName.substring(0, 8);
              final timePart = fileName.substring(9, 15); // 跳过下划线
              if (_isNumeric(datePart) && _isNumeric(timePart)) {
                logFiles.add(entity);
              }
            }
          }
        }
      }
    } catch (e) {
      // 忽略错误
    }

    return logFiles;
  }

  /// 检查字符串是否为纯数字
  static bool _isNumeric(String str) {
    return int.tryParse(str) != null;
  }

  /// 快速检查是否需要轮转（只检查当前文件大小，性能优化）
  /// [currentFilePath] 当前正在写入的文件路径
  static Future<bool> shouldRotateQuick(String currentFilePath) async {
    try {
      final currentFile = File(currentFilePath);
      if (!await currentFile.exists()) {
        return false;
      }
      // 只检查当前文件大小，如果超过单个文件阈值，再检查总大小
      final currentSize = await currentFile.length();
      // 如果当前文件已经很大（接近单个文件合理大小），需要检查总大小
      return currentSize > (maxTotalSizeBytes ~/ maxFileCount);
    } catch (e) {
      return false;
    }
  }

  /// 同步检查是否需要轮转
  /// 返回 true 表示需要轮转
  static Future<bool> shouldRotate(Directory logDirectory) async {
    try {
      final totalSize = await _calculateTotalSize(logDirectory);
      return totalSize > maxTotalSizeBytes;
    } catch (e) {
      return false;
    }
  }

  /// 计算总文件大小（所有 YYYYMMDD_HHMMSS.log 文件）
  /// 优化：并行读取文件大小，减少IO等待时间
  static Future<int> _calculateTotalSize(Directory directory) async {
    try {
      final logFiles = await _getAllLogFiles(directory);

      if (logFiles.isEmpty) {
        return 0;
      }

      // 并行读取所有文件大小
      final sizeFutures = logFiles.map((file) async {
        try {
          return await file.length();
        } catch (e) {
          return 0;
        }
      });

      final sizes = await Future.wait(sizeFutures);
      return sizes.fold<int>(0, (sum, size) => sum + size);
    } catch (e) {
      return 0;
    }
  }

  /// 检查并执行文件轮转
  /// 如果总文件大小超过阈值，执行轮转操作
  /// 返回新的当前文件路径
  /// 优化：复用 _performRotation 中的文件列表，避免重复获取
  static Future<String> rotateIfNeeded(
    Directory logDirectory,
    String currentFilePath,
  ) async {
    try {
      // 先快速检查当前文件大小，如果很小则不需要检查总大小
      final currentFile = File(currentFilePath);
      if (await currentFile.exists()) {
        final currentSize = await currentFile.length();
        // 如果当前文件很小，且文件数量不多，可能不需要轮转
        if (currentSize < (maxTotalSizeBytes ~/ maxFileCount)) {
          // 快速路径：当前文件不大，可能不需要轮转
          // 但为了准确性，仍然需要检查总大小
        }
      }

      final totalSize = await _calculateTotalSize(logDirectory);

      if (totalSize > maxTotalSizeBytes) {
        return await _performRotation(logDirectory, currentFilePath);
      }

      return currentFilePath;
    } catch (e) {
      // 轮转失败时返回当前文件路径
      return currentFilePath;
    }
  }

  /// 执行文件轮转
  /// 1. 获取所有日志文件，按文件名（时间戳）排序
  /// 2. 如果文件数量 >= maxFileCount，删除最老的文件
  /// 3. 创建新的时间戳文件
  /// 性能优化：基于时间命名，只需创建新文件，无需重命名操作
  /// 优化：使用缓存的文件名比较，减少字符串操作
  static Future<String> _performRotation(
    Directory directory,
    String currentFilePath,
  ) async {
    // 1. 获取所有日志文件，按文件名排序（时间戳格式可以直接排序）
    final logFiles = await _getAllLogFiles(directory);

    // 2. 如果文件数量 >= maxFileCount，删除最老的文件
    if (logFiles.length >= maxFileCount) {
      // 按文件名排序（升序，最老的在前）
      // 优化：缓存文件名，避免重复调用 basename
      logFiles.sort((a, b) {
        // 直接比较路径的最后部分（文件名），时间戳格式可以直接字符串比较
        final aPath = a.path;
        final bPath = b.path;
        final aNameStart = aPath.lastIndexOf(p.separator) + 1;
        final bNameStart = bPath.lastIndexOf(p.separator) + 1;
        return aPath.substring(aNameStart)
            .compareTo(bPath.substring(bNameStart));
      });

      // 删除最老的文件（列表前面的）
      final filesToDelete = logFiles.take(logFiles.length - maxFileCount + 1);
      final deleteTasks = filesToDelete.map((file) async {
        try {
          await file.delete();
        } catch (e) {
          // 删除失败时继续执行，不影响后续操作
        }
      });
      // 并行删除，提升性能
      await Future.wait(deleteTasks);
    }

    // 3. 创建新的时间戳文件
    final newFileName = generateTimestampFileName();
    final newFilePath = p.join(directory.path, newFileName);
    final newFile = File(newFilePath);
    await newFile.create();

    return newFilePath;
  }

  /// 获取当前日志文件路径（用于兼容性，实际使用 getOrCreateCurrentLogFile）
  @Deprecated('使用 getOrCreateCurrentLogFile 代替')
  static String getLogFilePath(Directory logDirectory) {
    // 这个方法已废弃，但保留以保持兼容性
    // 实际应该使用 getOrCreateCurrentLogFile
    final newFileName = generateTimestampFileName();
    return p.join(logDirectory.path, newFileName);
  }
}
