import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class PickerImageManager {
  static const int maxSizeInMB = 10 * 1024 * 1024;

  // 只从相册获取数据
  static void pickerPhotos({
    required BuildContext context,
    required void Function(
      String fiePath,
      double width,
      double height,
      int fileSize,
    )
    onSuccess,
  }) async {
    try {
      final List<AssetEntity>? result = await PickerImageManager.common(
        context,
      );
      if (result != null) {
        AssetEntity asset = result.last;
        String filePath = await PickerImageManager.getAssetImageFilePath(asset);
        int fileSize = await PickerImageManager.getAssetFileSize(asset);
        onSuccess(
          filePath,
          asset.width.toDouble(),
          asset.height.toDouble(),
          fileSize,
        );
      }
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      debugPrint('读取照片路径报错，请重试: $e-----$stackTrace');
    }
  }

  // 公共的选择方法
  static Future<List<AssetEntity>?> common(
    BuildContext context, {
    int maxAssetsCount = 1,
  }) async {
    return AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxAssetsCount,
        requestType: RequestType.image,
        textDelegate: const AssetPickerTextDelegate(),
      ),
    );
  }

  static Future<String> getAssetImageFilePath(AssetEntity asset) async {
    try {
      // 优先拿原图
      File? originalFile = await asset.originFile;

      /// 有些情况下 originFile 为 null，可以尝试 file
      originalFile ??= await asset.file;

      if (originalFile == null) {
        debugPrint('getAssetImageFilePath: 无法获取本地文件, asset id = ${asset.id}');
        return "";
      }
      return originalFile.path;
    } catch (error, stackTrace) {
      debugPrint('getAssetImageFilePath: 异常 = $error == $stackTrace');
      return "";
    }
  }

  static String getFileExtensionFromPath(String filePath) {
    if (filePath.isEmpty) {
      return '';
    }
    final String extensionWithDot = p.extension(
      filePath,
    ); // 如 ".png" / ".heic" / ""
    if (extensionWithDot.isEmpty) {
      return '';
    }
    final String extension = extensionWithDot.startsWith('.')
        ? extensionWithDot.substring(1)
        : extensionWithDot;

    return extension.toLowerCase();
  }

  /// 获取 AssetEntity 对应文件的大小（单位：byte）
  /// 返回 null 表示获取失败（比如在云端/权限问题等）
  static Future<int> getAssetFileSize(AssetEntity asset) async {
    try {
      // 优先原图
      File? file = await asset.originFile;
      // 有些情况 originFile 为 null，可以尝试 file
      file ??= await asset.file;

      if (file == null) {
        debugPrint('getAssetFileSize: 文件为 null, asset id = ${asset.id}');
        return 0;
      }
      final int length = await file.length(); // 单位：byte
      return length;
    } catch (e, s) {
      debugPrint('getAssetFileSize: 异常: $e');
      debugPrint('$s');
      return 0;
    }
  }

  // final cameraRes = await imagePicker.pickImage(
  //   source: ImageSource.camera,
  // );
  // if (cameraRes != null) {
  //   _images.add(cameraRes.path);
  // }
  // onSuccess?.call();
}
