import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/pages/utils/file/index.dart';
import 'package:voicetemplate/pages/model/upload_oss_model.dart';

class PersonLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  /// 用户数据
  var avatar = "".obs;
  var nickname = "".obs;
  var phone = "".obs;
  var signature = "".obs;
  final phoneBound = false.obs;

  String fileAvarPath = ''; // 文件的路径
  int filemeMemorySize = 0; // 单位字节 kb
  int fileId = 0; // resource_id

  /// 原始值（用于比较哪些字段被修改了）
  String _originalAvatar = "";
  String _originalNickname = "";
  String _originalSignature = "";

  /// 输入控制器
  final nicknameCtrl = TextEditingController();
  final signatureCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  /// 加载用户资料
  Future<void> loadProfile() async {
    final icon = global.avatar ?? "";
    avatar.value = icon.isEmpty
        ? "assets/images/mine/mine_info_empty.png"
        : icon;
    nickname.value = global.nickname ?? "";
    phone.value = global.phone ?? "";
    signature.value = global.sign ?? "";
    nicknameCtrl.text = nickname.value;
    signatureCtrl.text = signature.value;
    phoneCtrl.text = phone.value;
    phoneBound.value = phone.value.isNotEmpty;

    // 保存原始值用于比较
    _originalAvatar = icon.isEmpty
        ? "assets/images/mine/mine_info_empty.png"
        : icon;
    _originalNickname = global.nickname ?? "";
    _originalSignature = global.sign ?? "";
  }

  /// 上传头像 BuildContext context
  Future<void> handlePickAvatar(BuildContext context) async {
    try {
      final res = await PermissionUtil.requestPhotoAlbumPermission();
      if (!res) {
        showPermissionView("打开相册选图片以便更改头像");
        return;
      }
      if (!context.mounted) {
        return;
      }
      PickerImageManager.pickerPhotos(
        context: context,
        onSuccess:
            (String filePath, double width, double height, int fileSize) {
              filemeMemorySize = fileSize;
              debugPrint('从相册选择成功了: $filePath');
              getUploadInfo(filePath);
            },
      );
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      debugPrint('从相册选择😟😟😟😟: $e $stackTrace');
    }
  }

  // showMyBottomSheet([
  //   BottomSheetItem(
  //     title: '从相册选择',
  //     onPressed: () async {
  //       try {
  //         final res = await PermissionUtil.requestPhotoAlbumPermission();
  //         if (!res) {
  //           showPermissionView("打开相册选图片以便更改头像");
  //           return;
  //         }
  //         if (!context.mounted) {
  //           return;
  //         }
  //         PickerImageManager.pickerPhotos(
  //           context: context,
  //           onSuccess:
  //               (String filePath, double width, double height, int fileSize) {
  //                 fileSize = fileSize;
  //                 getUploadInfo(filePath);
  //               },
  //         );
  //       } catch (e, stackTrace) {
  //         showToast('读取照片路径报错，请重试');
  //         debugPrint('从相册选择😟😟😟😟: $e $stackTrace');
  //       }
  //     },
  //   ),
  // BottomSheetItem(
  //   title: '拍照',
  //   onPressed: () async {
  //     final res = await PermissionUtil.checkAndRequestCameraPermission();
  //     if (!res) {
  //       showPermissionView("打开相机并拍照以便更改头像");
  //       return;
  //     }

  // final cameraRes = await imagePicker.pickImage(
  //   source: ImageSource.camera,
  // );
  // if (cameraRes != null) {
  //   _images.add(cameraRes.path);
  // }
  // onSuccess?.call();
  //     },
  //   ),
  // ]);

  void showPermissionView(String content) {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: '提示',
        subTitle: '打开相册选图片以上传图片',
        sureTitle: "同意",
        sureAction: () {
          AppSettings.openAppSettings(type: AppSettingsType.settings);
        },
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  void getUploadInfo(String filePath) async {
    try {
      showLoading("上传中");
      final fileType = ImageCameraUtils.getFileExtensionFromPath(filePath);
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {"type": "user", "file_type": fileType, "field_type": "avatar"},
        converter: UploadOssModel.fromJson,
        showErrorToast: false,
      );
      if (result.code == 0) {
        String mimeType = mimeTypeMap[fileType] ?? "";
        fileAvarPath = result.data?.file ?? "";
        await uploadFile(result.data!, filePath, mimeType);
      } else {
        await PickerImageManager.deleteDirectory();
        SmartDialog.dismiss();
      }
    } catch (e) {
      await PickerImageManager.deleteDirectory();
      // 上传失败，恢复原始头像
      SmartDialog.dismiss();
    }
  }

  Future<void> uploadFile(
    UploadOssModel ossModel,
    String filePath,
    String mimeType,
  ) async {
    try {
      debugPrint('======res===== 开始${ossModel.signUrl} ');
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final res = await http.put(
        ossModel.signUrl,
        data: bytes,
        options: Options(
          contentType: mimeType, // ✅ 正常 MIME
          headers: {
            Headers.contentLengthHeader: bytes.length, // 很多存储要求带上
          },
        ),
        useBaseUrl: false,
        isNake: true,
      );
      if (res.isSuccess || (res.code == 200)) {
        // 上传成功后更新为服务器URL
        fileId = ossModel.resourceId;
        avatar.value = filePath;
      }
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss();
    } catch (e) {
      showToast("图片上传失败");
      debugPrint('======出错了===== $e ');
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss();
    }
  }

  Future<void> changeSave() async {
    if (nickname.value.trim().isEmpty) {
      showToast("请输入昵称");
      return;
    }
    // 构建只包含修改过的字段的数据
    final Map<String, dynamic> data = {};
    // 比较并只添加修改过的字段
    if (nickname.value != _originalNickname) {
      data["nickname"] = nickname.value;
    }
    if (signature.value != _originalSignature) {
      data["sign"] = signature.value;
    }
    // 头像比较：需要处理默认头像的情况
    if (avatar.value != _originalAvatar) {
      data["resource_id"] = fileId;
      data["file_size"] = "$filemeMemorySize"; // 后台要的大小是KB
    }
    debugPrint('file_size==$data====');
    if (data.isEmpty) {
      showToast("未修改用户信息");
      return;
    }
    showLoading("修改中");
    try {
      final result = await http.post(
        '/user/edit',
        data: data,
        showErrorToast: true,
      );
      SmartDialog.dismiss();
      if (result.code == 0) {
        global.updateUserInfo(
          nickname: nickname.value,
          sign: signature.value,
          avatar: fileAvarPath,
        );
        Get.back();
      }
    } catch (e) {
      SmartDialog.dismiss();
      debugPrint('===========  error: $e');
    }
  }
}
