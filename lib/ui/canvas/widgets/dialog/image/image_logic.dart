import 'package:path/path.dart' as p;
import 'package:common/common.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'package:voicetemplate/ui/utils/file/index.dart';
import 'package:voicetemplate/ui/model/index.dart';
import 'package:flutter/material.dart';
import 'dart:io';

//  SmartDialog.dismiss(status: SmartStatus.loading);

class ImageLogic extends GetxController {
  //上传成功
  Function(String imagePath, double width, double height)? onUploadSuccess;

  // 当前页码
  int currentPage = 1;

  // 图片列表
  final RxList<ImageModel> imageList = <ImageModel>[].obs;

  // 是否正在加载
  final RxBool isLoading = false.obs;

  // 是否正在刷新
  final RxBool isRefreshing = false.obs;

  // 是否还有更多
  final RxBool hasMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化时加载第一页数据
    loadImageList(refresh: true);
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadImageList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad() async {
    await loadImageList(refresh: false);
  }

  /// 加载图片列表
  /// [refresh] 是否为刷新操作（重置到第一页）
  Future<void> loadImageList({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      isRefreshing.value = true;
    } else {
      if (isLoading.value) {
        return;
      }
      isLoading.value = true;
    }

    try {
      final result = await http.get(
        '/user/material/index',
        query: {'page': '$currentPage', 'limit': globalPageSize},
        withToken: true,
        showErrorToast: false,
      );

      if (result.code == 0 && result.data != null) {
        final listModel = ImageListModels.fromJson(result.data);
        if (currentPage == 1) {
          imageList.clear();
        }
        if (listModel.items.isNotEmpty) {
          imageList.addAll(listModel.items);
          currentPage++;
          hasMore.value = true;
        } else {
          hasMore.value = false;
        }
      }
    } catch (e) {
      hasMore.value = false;
      debugPrint('加载图片列表失败: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// 上传图片 BuildContext context
  Future<void> pickerCanvalsImage(BuildContext context) async {
    try {
      // 权限请求
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
              getUploadInfo(filePath, fileSize, width, height);
            },
      );
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      debugPrint('从相册选择😟😟😟😟: $e $stackTrace');
    }
  }

  void getUploadInfo(
    String filePath,
    int fileSize,
    double width,
    double height,
  ) async {
    try {
      showLoading("上传中");
      final fileType = ImageCameraUtils.getFileExtensionFromPath(filePath);
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {
          "type": "material_user",
          "file_type": fileType,
          "field_type": "material_user_img",
        },
        converter: UploadOssModel.fromJson,
        showErrorToast: false,
        withToken: true,
      );
      debugPrint('===${result.code}=====获取图片上传url报错====${result.data}===');
      if ((result.code == 0 || result.code == 200) && result.data != null) {
        String mimeType = mimeTypeMap[fileType] ?? "";
        await uploadFile(
          result.data!,
          filePath,
          mimeType,
          fileSize,
          width,
          height,
        );
      } else {
        await PickerImageManager.deleteDirectory();
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('========获取图片上传url报错=====$e==');
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  Future<void> uploadFile(
    UploadOssModel ossModel,
    String filePath,
    String mimeType,
    int fileSize,
    double width,
    double height,
  ) async {
    try {
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
        withToken: true,
        showErrorToast: false,
        isNake: true,
      );

      /// 上传成功
      if (res.isSuccess) {
        await requestImage(
          filePath,
          ossModel.resourceId,
          fileSize,
          width,
          height,
        );
      } else {
        showToast("图片上传失败"); // 上传失败
        await PickerImageManager.deleteDirectory();
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      showToast("图片上传失败");
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 把获取到的信息传给后台
  Future<void> requestImage(
    String filePath,
    int resourceId,
    int fileSize,
    double width,
    double height,
  ) async {
    try {
      final result = await http.post(
        '/user/material/store',
        data: {
          "img_id": '$resourceId',
          "img_file_size": '$fileSize',
          "canvas_size": '$width:$height',
        },
        showErrorToast: false,
      );
      debugPrint('========>>>把获取到的信息传给后台=${result.code}==');
      if (result.code == 0 || result.code == 200) {
        await savePickerImage(filePath, width, height);
      } else {
        await PickerImageManager.deleteDirectory();
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      showToast("图片上传失败");
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  Future<void> savePickerImage(
    String filePath,
    double width,
    double height,
  ) async {
    try {
      final fileName = p.basenameWithoutExtension(filePath);
      final ext = ImageCameraUtils.getFileExtensionFromPath(filePath);
      final fileFormat = '$fileName.$ext';
      final fullPath = p.join(PickerImageManager.cavalsPath, fileFormat);

      /// 将临时保存的图片，保存到这新的路径下
      await copyImageFilePath(fromPath: filePath, toPath: fullPath);

      if (onUploadSuccess != null) {
        onUploadSuccess!(fileFormat, width, height);
      }
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);
    } catch (e) {
      showToast("图片上传失败");
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

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

  Future<File> copyImageFilePath({
    required String fromPath,
    required String toPath, // 目标“完整文件路径”（包含文件名）
    bool overwrite = true,
  }) async {
    final src = File(fromPath);
    if (!await src.exists()) {
      throw FileSystemException('Source file not found', fromPath);
    }
    // 确保目标目录存在
    await Directory(p.dirname(toPath)).create(recursive: true);
    final dst = File(toPath);
    if (overwrite && await dst.exists()) {
      await dst.delete();
    }
    return src.copy(toPath);
  }
}
