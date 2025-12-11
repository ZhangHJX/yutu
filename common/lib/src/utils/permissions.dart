import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'permission_overlay_widget.dart';

/// 权限工具类
class PermissionUtil {
  /// 获取Android SDK版本
  static Future<int> _getAndroidSdkVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      debugPrint('Android SDK版本: $sdkInt');
      return sdkInt;
    } catch (e) {
      debugPrint('获取Android SDK版本出错: $e');
      // 如果获取失败，尝试使用旧方法
      try {
        final version = int.parse(
          Platform.operatingSystemVersion.split(' ').last,
        );
        debugPrint('使用旧方法获取SDK版本: $version');
        return version;
      } catch (e2) {
        return 0;
      }
    }
  }

  /// 检查是否为Android 13或更高版本
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkVersion();
      final isHigher = sdkInt >= 33; // Android 13 是 API 33
      debugPrint('是否为Android 13或更高版本: $isHigher (SDK: $sdkInt)');
      return isHigher;
    }
    return false;
  }

  /// 请求相册读取权限
  static Future<bool> requestPhotoAlbumPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        if (status.isGranted || status.isLimited) {
          return true;
        }
        if (status.isDenied || status.isRestricted) {
          final requestStatus = await Permission.photos.request();
          if (requestStatus.isGranted || requestStatus.isLimited) {
            return true;
          }
        }
      } else if (Platform.isAndroid) {
        final isAndroid13Plus = await _isAndroid13OrHigher();
        debugPrint('Android版本判断: isAndroid13Plus=$isAndroid13Plus');

        if (isAndroid13Plus) {
          // Android 13+ 使用 photos 权限
          final status = await Permission.photos.status;
          debugPrint('Android 13+ 照片权限状态: $status');
          debugPrint(
            '权限状态详情: isGranted=${status.isGranted}, isDenied=${status.isDenied}, isPermanentlyDenied=${status.isPermanentlyDenied}, isRestricted=${status.isRestricted}',
          );

          if (status.isGranted) {
            debugPrint('照片权限已授予');
            return true;
          }

          if (status.isPermanentlyDenied) {
            debugPrint('照片权限被永久拒绝，需要引导用户去设置页面');
            return false;
          }

          if (status.isDenied) {
            debugPrint('照片权限被拒绝，准备请求权限...');
            // 1. 先显示权限说明浮层
            SmartDialog.show(
              builder: (context) => PermissionOverlayWidget(
                title: '权限使用说明',
                message: '打开相册以上传图片到编辑器中，进行进一步编辑、保存图片到相册，需要相册权限',
              ),
              alignment: Alignment.topCenter,
              animationType: SmartAnimationType.centerFade_otherSlide,
              animationTime: const Duration(milliseconds: 200),
              maskColor: Colors.transparent, // 透明遮罩，不阻挡系统对话框
              clickMaskDismiss: false,
              useAnimation: true,
              usePenetrate: true, // 重要：允许穿透，让系统对话框可以正常显示在上层
            );

            // 2. 等待一小段时间，让浮层显示出来
            await Future.delayed(const Duration(milliseconds: 300));

            // 3. 请求权限（此时系统对话框会弹出，显示在浮层上方）
            debugPrint('开始请求照片权限...');
            final requestStatus = await Permission.photos.request();
            debugPrint('请求照片权限后的状态: $requestStatus');
            debugPrint(
              '请求后状态详情: isGranted=${requestStatus.isGranted}, isDenied=${requestStatus.isDenied}, isPermanentlyDenied=${requestStatus.isPermanentlyDenied}',
            );

            // 4. 权限请求完成后，关闭浮层
            SmartDialog.dismiss();

            if (requestStatus.isGranted) {
              debugPrint('照片权限请求成功');
              return true;
            } else {
              debugPrint('照片权限请求失败，状态: $requestStatus');
            }
          } else {
            debugPrint('照片权限状态未知: $status');
          }
        } else {
          // Android 13 以下版本使用 storage 权限
          final status = await Permission.storage.status;
          debugPrint('Android <13 存储权限状态: $status');
          debugPrint(
            '权限状态详情: isGranted=${status.isGranted}, isDenied=${status.isDenied}, isPermanentlyDenied=${status.isPermanentlyDenied}, isRestricted=${status.isRestricted}',
          );

          if (status.isGranted) {
            debugPrint('存储权限已授予');
            return true;
          }

          if (status.isPermanentlyDenied) {
            debugPrint('存储权限被永久拒绝，需要引导用户去设置页面');
            // 权限被永久拒绝，request() 不会弹出对话框
            return false;
          }

          if (status.isDenied) {
            debugPrint('存储权限被拒绝，准备请求权限...');
            // 1. 先显示权限说明浮层
            SmartDialog.show(
              builder: (context) => PermissionOverlayWidget(
                title: '权限使用说明',
                message: '打开相册以上传图片到编辑器中，进行进一步编辑、保存图片到相册，需要相册权限',
              ),
              alignment: Alignment.topCenter,
              animationType: SmartAnimationType.centerFade_otherSlide,
              animationTime: const Duration(milliseconds: 200),
              maskColor: Colors.transparent, // 透明遮罩，不阻挡系统对话框
              clickMaskDismiss: false,
              useAnimation: true,
              usePenetrate: true, // 重要：允许穿透，让系统对话框可以正常显示在上层
            );

            // 2. 等待一小段时间，让浮层显示出来
            await Future.delayed(const Duration(milliseconds: 300));

            // 3. 请求权限（此时系统对话框会弹出，显示在浮层上方）
            debugPrint('开始请求存储权限...');
            final requestStatus = await Permission.storage.request();
            debugPrint('请求存储权限后的状态: $requestStatus');
            debugPrint(
              '请求后状态详情: isGranted=${requestStatus.isGranted}, isDenied=${requestStatus.isDenied}, isPermanentlyDenied=${requestStatus.isPermanentlyDenied}',
            );

            // 4. 权限请求完成后，关闭浮层
            SmartDialog.dismiss();

            if (requestStatus.isGranted) {
              debugPrint('存储权限请求成功');
              return true;
            } else {
              debugPrint('存储权限请求失败，状态: $requestStatus');
            }
          } else {
            debugPrint('存储权限状态未知: $status');
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
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
    return permissionGranted;
  }
}
