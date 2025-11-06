import 'dart:io';
import 'dart:typed_data';

import 'package:common/src/utils/index.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限工具类
class PermissionUtil {
  static final Dio _dio = Dio();

  /// 检查相册权限
  static Future<bool> checkPhotoPermission() async {
    try {
      // 针对不同平台检查不同权限
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        return status.isGranted;
      } else if (Platform.isAndroid) {
        // Android 13 (SDK 33)及以上版本需要分别检查读写权限
        if (await _isAndroid13OrHigher()) {
          final readStatus = await Permission.photos.status;
          return readStatus.isGranted;
        } else {
          // Android 13以下版本检查存储权限
          final status = await Permission.storage.status;
          return status.isGranted;
        }
      }
      return false;
    } catch (e) {
      debugPrint('检查相册权限出错: $e');
      return false;
    }
  }

  /// 检查是否为Android 13或更高版本
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkVersion();
      return sdkInt >= 33; // Android 13 是 API 33
    }
    return false;
  }

  /// 获取Android SDK版本
  static Future<int> _getAndroidSdkVersion() async {
    try {
      return int.parse(Platform.operatingSystemVersion.split(' ').last);
    } catch (e) {
      return 0;
    }
  }

  /// 请求相册权限
  static Future<bool> requestPhotoPermission() async {
    try {
      // 针对不同平台请求不同权限
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else if (Platform.isAndroid) {
        // Android 13及以上需要分别请求读写权限
        if (await _isAndroid13OrHigher()) {
          final readStatus = await Permission.photos.request();
          return readStatus.isGranted;
        } else {
          // Android 13以下请求存储权限
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }
      return false;
    } catch (e) {
      debugPrint('请求相册权限出错: $e');
      return false;
    }
  }

  /// 检查并请求相册权限
  static Future<bool> checkAndRequestPhotoPermission() async {
    // 先检查是否已有权限
    if (await checkPhotoPermission()) {
      return true;
    }

    // 请求权限
    return requestPhotoPermission();
  }

  /// 批量下载图片到相册（通过下载到本地再保存）
  static Future<bool> downloadImagesToGallery(
    List<String> imageUrls, {
    bool showResult = true,
    int quality = 80,
  }) async {
    int failCount = 0;

    try {
      // 检查并请求权限
      if (!await checkAndRequestPhotoPermission()) {
        if (showResult) {
          showToast('没有相册权限，请到设置中开启');
        }
        return false;
      }

      // 显示下载提示
      if (showResult) {
        showLoading('图片下载中...');
      }

      // 创建临时目录来保存图片
      final tempDir = await getTemporaryDirectory();

      for (final imageUrl in imageUrls) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savePath = path.join(tempDir.path, fileName);
        final response = await _dio.download(
          imageUrl,
          savePath,
          options: Options(responseType: ResponseType.bytes),
        );
        // 保存到相册
        if (response.statusCode == 200) {
          // 使用image_gallery_saver保存图片到相册
          final result = await ImageGallerySaverPlus.saveFile(
            savePath,
            name: fileName,
          );
          final bool isSuccess =
              result != null &&
              ((result is Map && result['isSuccess'] == true) ||
                  (result is bool && result));

          if (!isSuccess) {
            failCount++;
          }
        }
      }
    } catch (e) {
      failCount++;
    }

    if (showResult) {
      SmartDialog.dismiss();
      if (failCount > 0) {
        showToast('$failCount/${imageUrls.length}张图片下载失败');
      } else {
        showToast('图片下载成功');
      }
    }

    return failCount == 0;
  }

  /// 直接从URL保存图片到相册（不保存临时文件）
  static Future<bool> saveImageFromUrl(
    String imageUrl, {
    String? fileName,
    bool showResult = true,
    int quality = 80,
  }) async {
    try {
      // 检查并请求权限
      if (!await checkAndRequestPhotoPermission()) {
        if (showResult) {
          showToast('没有相册权限，请到设置中开启');
        }
        return false;
      }

      // 显示下载提示
      if (showResult) {
        showLoading('图片保存中...');
      }

      // 直接获取图片字节数据
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Uint8List bytes = Uint8List.fromList(response.data!);

        // 直接保存字节数据到相册
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: quality,
          name: fileName,
        );

        if (showResult) {
          SmartDialog.dismiss();
        }

        final bool isSuccess =
            result != null &&
            ((result is Map && result['isSuccess'] == true) ||
                (result is bool && result));

        if (isSuccess) {
          if (showResult) {
            showToast('图片已保存到相册');
          }
          return true;
        } else {
          if (showResult) {
            showToast('保存图片失败');
          }
          return false;
        }
      } else {
        if (showResult) {
          SmartDialog.dismiss();
          showToast('获取图片失败');
        }
        return false;
      }
    } catch (e) {
      if (showResult) {
        SmartDialog.dismiss();
        showToast('保存图片出错: $e');
      }
      return false;
    }
  }

  /// 保存内存中的图片数据到相册
  static Future<bool> saveImageBytes(
    Uint8List bytes, {
    String? fileName,
    bool showResult = true,
    int quality = 80,
  }) async {
    try {
      // 检查并请求权限
      if (!await checkAndRequestPhotoPermission()) {
        if (showResult) {
          showToast('没有相册权限，请到设置中开启');
        }
        return false;
      }

      if (showResult) {
        SmartDialog.showLoading(msg: '图片保存中...');
      }

      // 保存图片字节数据到相册
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: quality,
        name: fileName,
      );

      if (showResult) {
        SmartDialog.dismiss();
      }

      final bool isSuccess =
          result != null &&
          ((result is Map && result['isSuccess'] == true) ||
              (result is bool && result));

      if (isSuccess) {
        if (showResult) {
          showToast('图片已保存到相册');
        }
        return true;
      } else {
        if (showResult) {
          showToast('保存图片失败');
        }
        return false;
      }
    } catch (e) {
      if (showResult) {
        SmartDialog.dismiss();
        showToast('保存图片出错: $e');
      }
      return false;
    }
  }

  /// 检查相册读取权限
  static Future<bool> checkGalleryReadPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS平台检查照片权限
        final status = await Permission.photos.status;
        return status.isGranted;
      } else if (Platform.isAndroid) {
        // Android 13及以上版本需要检查读取媒体权限
        if (await _isAndroid13OrHigher()) {
          final readStatus = await Permission.photos.status;
          return readStatus.isGranted;
        } else {
          // Android 13以下版本检查存储权限
          final status = await Permission.storage.status;
          return status.isGranted;
        }
      }
      return false;
    } catch (e) {
      debugPrint('检查相册读取权限出错: $e');
      return false;
    }
  }

  /// 请求相册读取权限
  static Future<bool> requestGalleryReadPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          final readStatus = await Permission.photos.request();
          return readStatus.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }
      return false;
    } catch (e) {
      debugPrint('请求相册读取权限出错: $e');
      return false;
    }
  }

  /// 检查并请求相册读取权限
  static Future<bool> checkAndRequestGalleryReadPermission() async {
    // 先检查是否已有权限
    if (await checkGalleryReadPermission()) {
      return true;
    }

    // 请求权限
    final permissionGranted = await requestGalleryReadPermission();

    if (!permissionGranted) {
      showToast('没有相册读取权限，请到设置中开启');
    }

    return permissionGranted;
  }

  /// 检查相机权限
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('检查相机权限出错: $e');
      return false;
    }
  }

  /// 请求相机权限
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('请求相机权限出错: $e');
      return false;
    }
  }

  /// 检查并请求相机权限
  static Future<bool> checkAndRequestCameraPermission() async {
    // 先检查是否已有权限
    if (await checkCameraPermission()) {
      return true;
    }

    // 请求权限
    final permissionGranted = await requestCameraPermission();

    if (!permissionGranted) {
      showToast('没有相机权限，请到设置中开启');
    }

    return permissionGranted;
  }

  /// 检查并请求相机和相册权限（用于拍照和选择图片功能）
  static Future<Map<String, bool>>
  checkAndRequestCameraAndGalleryPermissions() async {
    final cameraPermission = await checkAndRequestCameraPermission();
    final galleryPermission = await checkAndRequestGalleryReadPermission();

    return {'camera': cameraPermission, 'gallery': galleryPermission};
  }
}
