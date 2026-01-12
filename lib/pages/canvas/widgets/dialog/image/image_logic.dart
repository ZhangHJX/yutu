import 'package:path/path.dart' as p;
import 'package:common/common.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/pages/utils/file/index.dart';
import 'package:voicetemplate/pages/model/index.dart';
import 'package:voicetemplate/file/index.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/core/index.dart';
import 'dart:io';

class ImageLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  //上传成功
  Function(String imagePath, double width, double height)? onUploadSuccess;
  // 当前页码
  int currentPage = 1;
  // 图片列表
  final RxList<ImageModel> imageList = <ImageModel>[].obs;
  // 是否正在加载
  final RxBool isLoading = false.obs;
  // 是否还有更多
  final RxBool hasMore = false.obs;

  GlobalKey refresherKey = GlobalKey();
  RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void onClose() {
    super.onClose();
    refreshController.dispose();
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化时加载第一页数据
    loadImageList(refresh: true);
    global.fetchUserInfo(); // 更新用户信息
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
    if (isLoading.value) {
      return;
    }
    if (refresh) {
      currentPage = 1;
    }
    isLoading.value = true;
    try {
      final result = await http.get(
        '/user/material/index',
        query: {'page': '$currentPage', 'limit': globalPageSize},
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
      isLoading.value = false;
      // 更新刷新控制器状态
      if (refresh) {
        debugPrint('更新刷新控制器状态: refresh ');
        refreshController.refreshCompleted();
      } else {
        debugPrint('更新刷新控制器状态: hasMore ');
        if (hasMore.value) {
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }
    } catch (e) {
      hasMore.value = false;
      debugPrint('加载图片列表失败: $e');
      isLoading.value = false;
      if (refresh) {
        refreshController.refreshFailed();
      } else {
        refreshController.loadFailed();
      }
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
              final materialSize =
                  double.tryParse(global.userInfo.value.designFileSize) ??
                  0 + fileSize.toDouble();
              final materialLimit =
                  double.tryParse(global.userInfo.value.designFileSizeLimit) ??
                  0;

              if (materialSize >= materialLimit) {
                SmartDialog.dismiss();
                showMaterialMemoryDialog();
              } else {
                getUploadInfo(filePath, fileSize, width, height);
              }
            },
      );
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      debugPrint('从相册选择😟😟😟😟: $e $stackTrace');
      await PickerImageManager.deleteDirectory();
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
      );
      if (result.code == 0 && result.data != null) {
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
        showErrorToast: false,
        isNake: true,
      );

      /// 上传成功
      if (res.isSuccess || (res.code == 200)) {
        await requestImage(filePath, ossModel, fileSize, width, height);
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
    UploadOssModel ossModel,
    int fileSize,
    double width,
    double height,
  ) async {
    try {
      final result = await http.post(
        '/user/material/store',
        data: {
          "img_id": '${ossModel.resourceId}',
          "img_file_size": '$fileSize',
          "canvas_size": '$width:$height',
        },
        showErrorToast: false,
      );
      if (result.code == 0) {
        await savePickerImage(ossModel, filePath, width, height);
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
    UploadOssModel ossModel,
    String filePath,
    double width,
    double height,
  ) async {
    try {
      // 使用 UploadOssModel 中 file 的文件名
      final fileFormat = Uri.parse(ossModel.file).pathSegments.last;

      // 1. 复制到 Application Support/localAsset 文件夹（不存在则创建）
      final localAssetDir = await DirectoryManager.getSupportSubDirectory(
        'localAsset',
      );
      final localAssetPath = p.join(localAssetDir.path, fileFormat);
      await copyImageFilePath(fromPath: filePath, toPath: localAssetPath);

      // 2. 同时复制到 Documents/cavals/images 目录
      final cavalsPath = p.join(PickerImageManager.cavalsPath, fileFormat);
      await copyImageFilePath(fromPath: filePath, toPath: cavalsPath);

      // 先关闭 loading 对话框，再触发回调关闭图片选择对话框
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);

      // 3. 将图片名、宽高通过 onUploadSuccess 传递到画布数据中，dialog 弹框消失
      if (onUploadSuccess != null) {
        onUploadSuccess!(fileFormat, width, height);
      }
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

  /// 显示是否保存为草稿
  void showMaterialMemoryDialog() {
    final textWidget = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 16.w,
          color: "#434343".color,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: '您的素材存储空间已满，请\n先去'),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GradientText(
              '"我的素材"',
              style: TextStyle(fontSize: 16.w, fontWeight: FontWeight.w500),
              colors: ["#8556FF".color, "#3691FF".color.withValues(alpha: 0.5)],
              stops: [0.7, 1.0],
            ),
          ),
          TextSpan(text: '页面整理已上传的\n素材，才能继续开始新的设计'),
        ],
      ),
    );

    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "存储空间已满",
        subTitleWidget: textWidget,
        sureTitle: "跳转我的素材",
        sureAction: () {
          Get.toNamed(AppRoutes.design);
        },
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: true,
      useAnimation: true,
      usePenetrate: false,
    );
  }
}
