part of '../canvals_file_manager.dart';

/// 通用操作
extension _CanvalsFileManagerHandle on CanvalsFileManager {
  /// 判断文件是否存在
  // Future<bool> exists({
  //   required String subDir,
  //   required String fileName,
  // }) async {
  //   final file = await getFileInSubDir(subDir, fileName);
  //   return file.exists();
  // }

  // /// 删除文件（不存在也不会报错）
  // Future<void> deleteFile({
  //   required String subDir,
  //   required String fileName,
  // }) async {
  //   final file = await getFileInSubDir(subDir, fileName);
  //   if (await file.exists()) {
  //     await file.delete();
  //   }
  // }

  // /// 列出某个子目录下的所有文件
  // Future<List<FileSystemEntity>> listFiles(String subDir) async {
  //   final dir = await getSubDirectory(subDir);
  //   if (!await dir.exists()) return [];
  //   return dir.list().toList();
  // }
}
