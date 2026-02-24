import 'package:common/common.dart';
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/pages/model/index.dart';
import 'dart:io';

class AppInfoLogic extends GetxController {
  /// 全局
  final global = Get.find<GlobalLogic>();

  /// 初始化一些假数据
  @override
  void onInit() {
    super.onInit();
  }

  /// 上传日志文件（需要外部实现上传逻辑）
  /// [uploadCallback] 接收 zip 文件路径，返回是否上传成功
  Future<void> uploadLogs() async {
    showLoading('上传中...');
    try {
      final result = await http.post<UploadOssModel>(
        '/upload/generateLogUploadUrl',
        converter: UploadOssModel.fromJson,
      );
      if (result.code == 0 && result.data != null) {
        _uploadZipFileStream(result.data!);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      AppLogger.error('日志获取上传URL报错', e);
    }
  }

  Future<void> _uploadZipFileStream(UploadOssModel ossModel) async {
    final zipPath = await LogUploader.instance.packLogsToZip();
    if (zipPath == null) {
      AppLogger.info("获取日志压缩路径报错");
      SmartDialog.dismiss(status: SmartStatus.loading);
      return;
    }
    final file = File(zipPath);
    if (!await file.exists()) throw Exception('zip file not found');
    final contentLength = await file.length();
    final stream = file.openRead();

    final mimeType = mimeTypeMap["zip"] ?? "";
    final res = await http.put(
      ossModel.signUrl,
      data: stream,
      options: Options(
        contentType: mimeType,
        sendTimeout: Duration(seconds: 120),
        headers: {Headers.contentLengthHeader: contentLength},
      ),
      useBaseUrl: false,
      isNake: true,
    );
    if (res.isSuccess || (res.code == 200)) {
      AppLogger.info("日志上传成功");
    }
    try {
      await File(zipPath).delete();
      AppLogger.info("日志打包路径删除成功");
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast('日志上传成功');
      Get.back();
    } catch (e) {
      // 忽略删除失败
      AppLogger.error("日志打包路径删除失败", e);
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }
}
