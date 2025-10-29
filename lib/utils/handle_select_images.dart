import 'dart:collection';

import 'package:common/common.dart';
import 'package:flutter/material.dart';

class SelectImageHelper {
  SelectImageHelper({required this.maxCount});

  final int maxCount;

  final _images = <String>[].obs;

  final imagePicker = ImagePicker();

  List<String> get images => UnmodifiableListView(_images);

  String? get image => images.firstOrNull;

  void onChooseImages({VoidCallback? onSuccess}) {
    showMyBottomSheet([
      BottomSheetItem(
        title: '从相册选择',
        onPressed: () async {
          try {
            final res = await PermissionUtil.requestGalleryReadPermission();
            if (!res) {
              return showToast('没有相册读取权限，请到设置中开启');
            }

            final left = maxCount - _images.length;
            if (maxCount == 1 || left == 1) {
              final res = await imagePicker.pickImage(
                source: ImageSource.gallery,
              );
              if (maxCount == 1) {
                _images.value = [?res?.path];
              } else {
                _images.addIf(res?.path != null, res!.path);
              }
            } else {
              _images.addAll(
                (await imagePicker.pickMultiImage(
                  limit: left,
                )).map((e) => e.path),
              );
            }
            onSuccess?.call();
          } catch (e, stackTrace) {
            showToast('读取照片路径报错，请重试');
            debugPrint('从相册选择😟😟😟😟: $e');
            debugPrint('从相册选择😡😡😡😡: $stackTrace');
          }
        },
      ),
      BottomSheetItem(
        title: '拍照',
        onPressed: () async {
          final res = await PermissionUtil.requestCameraPermission();
          if (!res) {
            return showToast('没有相机权限，请到设置中开启');
          }

          final cameraRes = await imagePicker.pickImage(
            source: ImageSource.camera,
          );
          if (cameraRes != null) {
            _images.add(cameraRes.path);
          }
          onSuccess?.call();
        },
      ),
    ]);
  }

  // 只从相册获取数据
  void onlyChooseImages({VoidCallback? onSuccess}) async {
    try {
      final res = await PermissionUtil.requestGalleryReadPermission();
      if (!res) {
        return showToast('没有相册读取权限，请到设置中开启');
      }

      final left = maxCount - _images.length;
      if (maxCount == 1 || left == 1) {
        final res = await imagePicker.pickImage(source: ImageSource.gallery);
        if (maxCount == 1) {
          _images.value = [?res?.path];
        } else {
          _images.addIf(res?.path != null, res!.path);
        }
      } else {
        _images.addAll(
          (await imagePicker.pickMultiImage(limit: left)).map((e) => e.path),
        );
      }
      onSuccess?.call();
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      debugPrint('从相册选择😟😟😟😟: $e');
      debugPrint('从相册选择😡😡😡😡: $stackTrace');
    }
  }

  void onDeleteImage(String path) {
    _images.remove(path);
  }
}
