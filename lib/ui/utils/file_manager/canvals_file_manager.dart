import 'package:common/common.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

// 扩展类
part './extension/canvals_file_manager_rw.dart';
part './extension/canvals_file_manager_handle.dart';

/// 本地文件管理工具（单例）
/// - 初始化应用目录
/// - 获取常用路径（文档目录、缓存目录）

/// - 在指定子目录下读写文本 / JSON
/// - 判断文件是否存在、删除文件
class CanvalsFileManager {
  CanvalsFileManager._internal();
  static final CanvalsFileManager instance = CanvalsFileManager._internal();

  bool _inited = false;
  late Directory _appDocDir; // 应用文档目录（建议所有持久数据都放这里）
  late Directory _tempDir; // 临时目录（可缓存一些数据）

  /// 在文档目录下创建
  Future<void> init() async {
    if (_inited) return;
    _appDocDir = await getApplicationDocumentsDirectory();
    _tempDir = await getTemporaryDirectory();
    _inited = true;
  }

  Future<void> _ensureInit() async {
    if (!_inited) {
      await init();
    }
  }

  /// 获取临时目录路径
  Future<String> getTempPath() async {
    await _ensureInit();
    return _tempDir.path;
  }

  /// 获取应用文档根目录路径
  Future<String> getAppDocPath() async {
    await _ensureInit();
    return _appDocDir.path;
  }

  /// 在文档目录下创建 / 获取子目录：比如 subDir = 'drafts' -> {docDir}/drafts
  Future<Directory> getSubDirectory(String subDir) async {
    final dir = Directory(p.join(getAppDocPath().toString(), subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 获取某个子目录下的 File 对象（不会实际创建文件）
  Future<File> getFileInSubDir(String subDir, String fileName) async {
    final dir = await getSubDirectory(subDir);
    return File(p.join(dir.path, fileName));
  }
}
