import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:common/common.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/core/index.dart';
import 'package:voicetemplate/pages/model/index.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/stores/global.dart';
import 'manager/local_asset_store.dart';
import 'manager/material_manager.dart';
import 'dart:io';

class ImageLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  //上传成功
  Function(List<PickerInfoModel> list)? onUploadSuccess;
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

  /// 当前选中的素材索引（单选）
  int? selectedIndex;

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
        AppLogger.info('更新刷新控制器状态: refresh');
        refreshController.refreshCompleted();
      } else {
        AppLogger.info('更新刷新控制器状态: hasMore');
        if (hasMore.value) {
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }
    } catch (e) {
      hasMore.value = false;
      AppLogger.error('加载图片列表失败:', e);
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
    if (global.connectStatus.currentStatus == Status.none) {
      showToast("上传失败");
      return;
    }
    if (!global.isLogin) {
      SmartDialog.dismiss();
      Get.toNamed(AppRoutes.appLogin);
      return;
    }

    try {
      // 权限请求
      final res = await PermissionUtil.requestPhotoAlbumPermission();
      if (!res) {
        showPermissionView();
        return;
      }
      if (!context.mounted) {
        return;
      }
      PickerImageManager.pickerPhotos(
        context: context,
        maxCount: 9,
        onSuccess: (List<PickerInfoModel> list) {
          checkLocalHaveResource(list);
        },
      );
    } catch (e, stackTrace) {
      showToast('读取照片路径报错，请重试');
      AppLogger.error('从相册选择😟😟😟😟:', e, stackTrace);
      await PickerImageManager.deleteDirectory();
    }
  }

  /// 本地检查是否有相同的文件
  void checkLocalHaveResource(List<PickerInfoModel> list) async {
    //1、获取所有的hash值
    final hashValues = list
        .map((e) => e.hashValue.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    // 获取本地已有的图片记录（按 hashValue 匹配）
    final localResults = await LocalAssetStore.instance.getExistingHashValues(
      hashValues,
    );

    // 已存在的 hash 集合
    final repeatHashSet = localResults
        .map((e) => e.hashValue.trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    // 获取本地没有的图片数据
    // final localResults = list.where((item) {
    //   final h = item.hashValue.trim();
    //   return repeatHashSet.contains(h);
    // }).toList();

    for (final model in localResults) {
      AppLogger.info('=====本地查询的图片的文件名称===${model.fileName}');
    }

    final localNoResults = list.where((item) {
      final h = item.hashValue.trim();
      return !repeatHashSet.contains(h);
    }).toList();

    /// 如果有本地没有的图片
    if (localNoResults.isNotEmpty) {
      double materialSize = global.materialSize;
      double materialLimit = global.materialLimit;
      double totalSize = localNoResults.fold<double>(
        0,
        (sum, item) => sum + item.fileSize,
      );
      materialSize += totalSize;

      if (materialSize >= materialLimit) {
        SmartDialog.dismiss();
        showMaterialMemoryDialog();
      } else {
        AppLogger.info(
          '上传个数${localNoResults.length}==本地个数${localResults.length}',
        );
        getUploadInfo(localNoResults, localResults);
      }
    } else {
      showLoading("上传中");

      /// 全部都在本地数据库
      for (final model in localResults) {
        await _copyImageToCanvalsPath(model);
      }
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast('上传成功');
      if (onUploadSuccess != null) {
        onUploadSuccess!(localResults);
      }
    }
  }

  /// 并发请求单个文件的上传 URL
  Future<UploadOssModel?> _requestOneUploadUrl(PickerInfoModel item) async {
    try {
      final fileType = ImageHandleUtils.getFileExtensionFromPath(item.filePath);
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {
          "type": "material_user",
          "file_type": fileType,
          "field_type": "material_user_img",
        },
        converter: UploadOssModel.fromJson,
      );
      if (result.code == 0 && result.data != null) {
        return result.data;
      }
    } catch (e) {
      AppLogger.error('获取上传 URL 失败:', e);
    }
    return null;
  }

  /// 单文件：只负责流式上传到 OSS，并计算 hash，供后续批量 store 使用
  Future<(PickerInfoModel, UploadOssModel)?> _uploadSingleToOss(
    PickerInfoModel item,
    UploadOssModel ossModel,
  ) async {
    try {
      final fileType = ImageHandleUtils.getFileExtensionFromPath(item.filePath);
      final mimeType = mimeTypeMap[fileType] ?? "";
      final file = File(item.filePath);
      if (!await file.exists()) return null;
      final contentLength = await file.length();
      final stream = file.openRead();

      final res = await http.put(
        ossModel.signUrl,
        data: stream,
        options: Options(
          contentType: mimeType,
          headers: {Headers.contentLengthHeader: contentLength},
        ),
        useBaseUrl: false,
        isNake: true,
      );
      if (!res.isSuccess && res.code != 200) {
        return null;
      }
      return (item, ossModel);
    } catch (e) {
      AppLogger.error('上传 OSS 失败:', e);
    }
    return null;
  }

  void getUploadInfo(
    List<PickerInfoModel> localNoResults,
    List<PickerInfoModel> localResults,
  ) async {
    if (localNoResults.isEmpty) return;
    try {
      showLoading("上传中");

      // 1. 并发获取上传 URL 数组
      final urlResults = await Future.wait(
        localNoResults.map((item) => _requestOneUploadUrl(item)),
      );

      final pairs = <(PickerInfoModel, UploadOssModel)>[];
      for (var i = 0; i < localNoResults.length; i++) {
        if (urlResults[i] != null) {
          pairs.add((localNoResults[i], urlResults[i]!));
        }
      }
      if (pairs.isEmpty) {
        SmartDialog.dismiss(status: SmartStatus.loading);
        await PickerImageManager.deleteDirectory();
        showToast('获取上传地址失败，请重试');
        return;
      }

      // 2. 并发上传到各自 signUrl（仅上传到 OSS，不调用 store）
      final uploadResults = await Future.wait(
        pairs.map((p) => _uploadSingleToOss(p.$1, p.$2)),
      );

      final successes = uploadResults
          .whereType<(PickerInfoModel, UploadOssModel)>()
          .toList();

      if (successes.isEmpty) {
        SmartDialog.dismiss(status: SmartStatus.loading);
        await PickerImageManager.deleteDirectory();
        showToast('上传失败，请重试');
        return;
      }

      // 3. 统一调用 store，批量写入服务器
      final storePayload = successes
          .map(
            (tuple) => {
              "img_id": '${tuple.$2.resourceId}',
              "img_file_size": '${tuple.$1.fileSize}',
              "canvas_size": '${tuple.$1.width}:${tuple.$1.height}',
              "hash_value": tuple.$1.hashValue,
            },
          )
          .toList();

      final storeResult = await http.post(
        '/user/material/stores',
        data: {'data': jsonEncode(storePayload)},
      );

      if (storeResult.code != 0) {
        SmartDialog.dismiss(status: SmartStatus.loading);
        await PickerImageManager.deleteDirectory();
        showToast('上传失败，请重试');
        return;
      }

      // 4. 全部结果后再处理：复制文件、回调、关 loading、删目录
      for (final tuple in successes) {
        final item = tuple.$1;
        final ossModel = tuple.$2;
        await _savePickerImageAfterUpload(ossModel, item);
      }

      // 5. 将本地有的
      for (final model in localResults) {
        await _copyImageToCanvalsPath(model);
      }

      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast(successes.length == localNoResults.length ? '上传成功' : '部分上传成功');
      await PickerImageManager.deleteDirectory();
      if (onUploadSuccess != null) {
        final List<PickerInfoModel> pickerList = successes
            .map((t) => t.$1)
            .toList();
        onUploadSuccess!(pickerList);
      }
    } catch (e) {
      AppLogger.error('批量上传失败:', e);
      await PickerImageManager.deleteDirectory();
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast('上传失败，请重试');
    }
  }

  /// 上传并 store 成功后仅做本地复制（不 dismiss、不删目录）
  Future<void> _savePickerImageAfterUpload(
    UploadOssModel ossModel,
    PickerInfoModel model,
  ) async {
    final fileFormat = Uri.parse(ossModel.file).pathSegments.last;
    final localAssetDir = await DirectoryManager.getSupportSubDirectory(
      'localAsset',
    );

    model.fileName = fileFormat;

    // 将数据保存到数据库
    await LocalAssetStore.instance.save(model);

    /// copy到本地资源库
    final localAssetPath = p.join(localAssetDir.path, fileFormat);
    await copyImageFilePath(fromPath: model.filePath, toPath: localAssetPath);

    ///copy到画布图片库
    final cavalsPath = p.join(PickerImageManager.cavalsPath, fileFormat);
    await copyImageFilePath(fromPath: model.filePath, toPath: cavalsPath);
  }

  void showPermissionView() {
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

  /// 显示是否保存为素材
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
          SmartDialog.dismiss();
          Get.toNamed(AppRoutes.stock);
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

  /// 点击素材列表进行处理
  Future<void> selectedImageAction() async {
    final index = selectedIndex;
    if (index == null || index < 0 || index >= imageList.length) {
      showToast('请选择一张图片');
      return;
    }
    final model = imageList[index];
    try {
      showLoading('正在添加图片');

      // 设置下载后 移动的位置
      final fileName = Uri.parse(model.image).pathSegments.last;
      final localAssetDir = await DirectoryManager.getSupportSubDirectory(
        'localAsset',
      );
      final localPath = p.join(localAssetDir.path, fileName);
      // 从数据库查询本地是否存在
      PickerInfoModel? localModel = await LocalAssetStore.instance
          .getByFileName(fileName);

      if (localModel != null) {
        final File targetFile = File(localPath);
        await MaterialManager.instance.ensureImageInCanvasImages(
          targetFile,
          fileName,
        );
      } else {
        // 使用 background_downloader 下载到 Support localAsset
        await MaterialManager.instance.ensureImageInLocalAsset(
          model.image,
          fileName,
          localPath,
        );
        final File targetFile = File(localPath);
        await MaterialManager.instance.ensureImageInCanvasImages(
          targetFile,
          fileName,
        );
        final result = getCanvasSizeWH(model.canvasSize);
        localModel = PickerInfoModel();
        localModel.fileName = fileName;
        localModel.width = result.$1;
        localModel.height = result.$2;
        final int targetSize = await targetFile.length();
        final int fileSizeKb = (targetSize / 1024).ceil();
        localModel.fileSize = fileSizeKb;
        localModel.hashValue = await PickerImageManager.sha256OfFile(
          targetFile,
        );
        await LocalAssetStore.instance.save(localModel);
      }

      // 先关闭 loading 对话框，再触发回调关闭图片选择对话框
      SmartDialog.dismiss(status: SmartStatus.loading);

      if (onUploadSuccess != null) {
        onUploadSuccess!([localModel]);
      }
    } catch (e, stackTrace) {
      AppLogger.error('添加图片到画布失败:', e, stackTrace);
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast('添加图片失败，请稍后重试');
    }
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

  /// 从 localAsset 复制到画布图片库（仅当画布侧尚无该文件时复制）
  Future<void> _copyImageToCanvalsPath(PickerInfoModel model) async {
    AppLogger.info('进入到copy目录的操作==${model.fileName}');
    if (model.fileName.trim().isEmpty) return;

    final localAssetDir = await DirectoryManager.getSupportSubDirectory(
      'localAsset',
    );
    final localAssetPath = p.join(localAssetDir.path, model.fileName);

    final srcFile = File(localAssetPath);
    if (!await srcFile.exists()) {
      AppLogger.info(
        '_copyImageToCanvalsPath: 本地资源不存在，跳过复制, fileName=${model.fileName}',
      );
      return;
    }

    final isHave = await isHaveLocalImage(model.fileName);
    AppLogger.info('查询画布中本地草稿中是否有此图片=$isHave');

    if (!isHave) {
      final cavalsPath = p.join(PickerImageManager.cavalsPath, model.fileName);
      await copyImageFilePath(fromPath: localAssetPath, toPath: cavalsPath);
    }
  }

  /// 判断画
  /// 布编辑器本地有没有图片
  Future<bool> isHaveLocalImage(String fileName) async {
    if (fileName.trim().isEmpty) return false;
    final filePath = p.join(PickerImageManager.cavalsPath, fileName);

    final file = File(filePath);
    return file.exists(); // true 表示存在
  }
}
