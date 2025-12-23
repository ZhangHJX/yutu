import 'package:path/path.dart' as p;
import 'dart:io';

class FileManager {
  /// 写入文本文件（覆盖写）
  static Future<File> writeTextFile({
    required Directory directory,
    required String fileName,
    required String content,
  }) async {
    final String filePath = p.join(directory.path, fileName);
    final File file = File(filePath);
    return file.writeAsString(content);
  }

  /// 读取文本文件，不存在则返回 null
  static Future<String?> readTextFile({
    required Directory directory,
    required String fileName,
  }) async {
    final String filePath = p.join(directory.path, fileName);
    final File file = File(filePath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  /// 判断文件是否存在
  static Future<bool> isFileExists({
    required Directory directory,
    required String fileName,
  }) async {
    final String filePath = p.join(directory.path, fileName);
    final File file = File(filePath);
    return file.exists();
  }

  /// 删除文件（如不存在则直接返回）
  static Future<void> deleteFile({
    required Directory directory,
    required String fileName,
  }) async {
    final String filePath = p.join(directory.path, fileName);
    final File file = File(filePath);
    if (!await file.exists()) {
      return;
    }
    await file.delete();
  }

  /// 清空目录内容（默认保留目录本身）
  /// - [deleteDirItself] 为 true 时：连目录一起删除
  static Future<void> deleteDirectory(
    Directory directory, {
    bool deleteDirectory = false,
  }) async {
    if (!await directory.exists()) return;

    if (deleteDirectory) {
      await directory.delete(recursive: true);
      return;
    }

    await for (final entity in directory.list(
      recursive: false,
      followLinks: false,
    )) {
      await entity.delete(recursive: true);
    }
  }
}


/*
1. 在文档目录中保存一个 JSON 文本
    Future<void> saveProjectJson(String projectId, String jsonContent) async {
      // /Documents/projects
      final Directory dir =
          await PathUtils.getDocumentsSubDirectory('projects');

      // 文件名：project_<id>.json
      await PathUtils.writeTextFile(
        directory: dir,
        fileName: 'project_$projectId.json',
        content: jsonContent,
      );
    }

2、从文档目录读取这个 JSON
    Future<String?> loadProjectJson(String projectId) async {
      final Directory dir =
          await PathUtils.getDocumentsSubDirectory('projects');

      final String? content = await PathUtils.readTextFile(
        directory: dir,
        fileName: 'project_$projectId.json',
      );

      return content;
    }

3、在 Support 目录中保存远程字体
    Future<File> saveRemoteFont(String fontFileName, List<int> bytes) async {
      final Directory fontsDir =
          await PathUtils.getSupportSubDirectory('fonts');

      final String path = p.join(fontsDir.path, fontFileName);
      final File file = File(path);
      return file.writeAsBytes(bytes, flush: true);
    }
*/ 
