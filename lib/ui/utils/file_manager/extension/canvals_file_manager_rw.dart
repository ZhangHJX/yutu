part of '../canvals_file_manager.dart';

extension _CanvalsFileManagerRW on CanvalsFileManager {
  // =====================
  // 文本读写
  // =====================

  /// 写入纯文本文件（UTF8）
  // Future<File> writeTextFile({
  //   required String subDir,
  //   required String fileName,
  //   required String content,
  // }) async {
  //   final file = await getFileInSubDir(subDir, fileName);
  //   return file.writeAsString(content, flush: true);
  // }

  /// 读取纯文本文件，文件不存在返回 null
  // Future<String?> readTextFile({
  //   required String subDir,
  //   required String fileName,
  // }) async {
  //   final file = await getFileInSubDir(subDir, fileName);
  //   if (!await file.exists()) return null;
  //   return file.readAsString();
  // }

  // /// 写入 JSON 文件（自动 jsonEncode）
  // Future<File> writeJsonFile({
  //   required String subDir,
  //   required String fileName,
  //   required Object jsonObject,
  // }) async {
  //   final content = jsonEncode(jsonObject);
  //   return writeTextFile(subDir: subDir, fileName: fileName, content: content);
  // }

  // /// 读取 JSON 文件并 decode，文件不存在返回 null
  // Future<dynamic> readJsonFile({
  //   required String subDir,
  //   required String fileName,
  // }) async {
  //   final text = await readTextFile(subDir: subDir, fileName: fileName);
  //   if (text == null) return null;
  //   return jsonDecode(text);
  // }
}
