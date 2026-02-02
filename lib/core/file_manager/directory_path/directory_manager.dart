import 'package:common/common.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class DirectoryManager {
  /// 文档目录：适合用户业务数据
  static Future<Directory> getDocumentsDirectory() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return dir;
  }

  /// 应用支持目录：适合配置、数据库、远程字体等
  static Future<Directory> getSupportDirectory() async {
    final Directory dir = await getApplicationSupportDirectory();
    return dir;
  }

  /// 临时目录：系统可随时清理
  static Future<Directory> getTempDirectory() async {
    final Directory dir = await getTemporaryDirectory();
    return dir;
  }

  /// 在文档目录下创建子目录
  static Future<Directory> getDocumentsSubDirectory(String subPath) async {
    final Directory docDir = await DirectoryManager.getDocumentsDirectory();
    return getOrCreateSubDirectory(docDir, subPath);
  }

  /// 在应用支持目录下创建子目录
  static Future<Directory> getSupportSubDirectory(String subPath) async {
    final Directory supportDir = await DirectoryManager.getSupportDirectory();
    return getOrCreateSubDirectory(supportDir, subPath);
  }

  /// 在应用临时目录下创建子目录
  static Future<Directory> getTempSubDirectory(String subPath) async {
    final Directory supportDir = await DirectoryManager.getTempDirectory();
    return getOrCreateSubDirectory(supportDir, subPath);
  }

  /// 在指定根目录下创建子目录（例如：supportDir + /fonts）
  static Future<Directory> getOrCreateSubDirectory(
    Directory rootDir,
    String subPath,
  ) async {
    final String fullPath = p.join(rootDir.path, subPath);
    final Directory directory = Directory(fullPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
/*

“用户的东西” → Documents
“App 自己的东西” → ApplicationSupport

1、getApplicationDocumentsDirectory()
	•	需要和用户账号强绑定的业务数据：
	      •	比如：画布工程 JSON、用户导入的文件、笔记等
  •	将来你可能会做：
	      •	备份/恢复
      	•	导出/导入
	      •	跨设备同步


2、getApplicationSupportDirectory() 
  •	远程下载字体
	•	远程配置文件（feature 开关、AB 配置缓存）
	•	本地数据库 / 索引文件
	•	模板资源、图片资源包、解压后的 assets
	•	不需要给用户直接“看到和操作”的内部文件


3、getTemporaryDirectory()
  临时目录，系统认为“我随时可以删”
    •	适合短期缓存：
    •	图片解码中间文件
    •	一次性下载临时 zip

*/ 