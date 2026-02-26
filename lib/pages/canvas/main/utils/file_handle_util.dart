import 'package:voicetemplate/core/index.dart';
import 'package:common/common.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class FileHandleUtil {
  static Future<void> deleteCanvalsImage(String fileName) async {
    final filePath = p.join(PickerImageManager.cavalsPath, fileName);

    final file = File(filePath);

    try {
      final exists = await file.exists();
      if (!exists) return;
      await file.delete();
      AppLogger.info('画布中图片文件，删除成功！');
    } catch (_) {
      AppLogger.info('画布中图片文件，删除失败！');
    }
  }
}
