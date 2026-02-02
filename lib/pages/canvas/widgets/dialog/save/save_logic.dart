import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/pages/canvas/pages/canvals/canvals_controller.dart';
import 'package:voicetemplate/pages/model/index.dart';
import 'package:voicetemplate/file/index.dart';
import 'package:voicetemplate/pages/canvas/model/index.dart';
import 'package:voicetemplate/pages/canvas/draft/index.dart';
import 'model/save_response.dart';
import 'package:voicetemplate/pages/middle/manager/index.dart';
import 'package:voicetemplate/stores/global.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/core/index.dart';
import 'package:uuid/uuid.dart';

/// 上传请求单独的超时时间（大文件上传）
const _uploadSendTimeout = Duration(seconds: 120);

/// 供 compute 调用的顶层函数：在 isolate 中打 zip，避免阻塞 UI
Future<void> _createZipFromDirectoryInIsolate(
  Map<String, String> params,
) async {
  final sourceDir = Directory(params['sourcePath']!);
  final zipFile = File(params['zipPath']!);
  await ZipFile.createFromDirectory(
    sourceDir: sourceDir,
    zipFile: zipFile,
    recurseSubDirs: true,
    includeBaseDirectory: true,
  );
}

class SaveLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  // 获取画布控制器
  final canvalsLogic = Get.find<CanvalsController>();

  final Uuid uuid = Uuid();

  /// 画布的图片信息
  int imageMemorySize = 0; // 单位字节 kb
  int imageResourceId = 0; // 图片的id

  /// 本地文件相关信息
  int fileMemorySize = 0; // 单位字节 kb
  int fileResourceId = 0; // 文件的id

  // 文本控制器
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  ///应用场景
  final scenarios = <ScreenItemModel>[].obs;
  List<String> itemArray = <String>[];
  final showScenarioDropdown = false.obs;
  RxString sceneName = ''.obs;

  RxBool tempteIsNewCreate = true.obs;
  RxBool draftIsCreate = true.obs;

  ///风格标签
  final suggestedTags = <ScreenItemModel>[].obs;
  final selectedTags = <ScreenItemModel>[].obs;

  final isSaveTemplate = false.obs;

  /// 是否可以保存画布
  final isCanSave = false.obs;

  // 用于监听的工作器
  Worker? _validationWorker;

  /// 上传进度 0.0 ~ 1.0（zip 上传），供 UI 显示进度条
  final uploadProgress = 0.0.obs;

  Uint8List? canvalsImage;

  @override
  void onClose() {
    _validationWorker?.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  @override
  void onInit() async {
    super.onInit();

    _setupValidationListener(); // 设置监听

    await getSceneResource();
    await getSuggestedTags();
    global.fetchUserInfo();
    updateTemplateInfo();
  }

  /// 设置验证监听，当标题、描述、应用场景、风格标签都有值时更新 isCanSave
  void _setupValidationListener() {
    // 监听标题变化
    titleController.addListener(_checkCanSave);

    // 监听描述变化
    // descriptionController.addListener(_checkCanSave);
    //    selectedTags,

    // 监听应用场景变化
    _validationWorker = everAll([sceneName], (_) => _checkCanSave());

    // 初始化时检查一次
    _checkCanSave();
  }

  /// 检查是否可以保存（标题、描述、应用场景、风格标签都有值）
  void _checkCanSave() {
    final hasTitle = titleController.text.trim().isNotEmpty;
    final hasScene = sceneName.value.isNotEmpty;
    final canSave = hasTitle && hasScene;
    if (isCanSave.value != canSave) {
      isCanSave.value = canSave;
    }
  }

  void updateTemplateInfo() {
    titleController.text = canvalsLogic.canvasModel.title;
    descriptionController.text = canvalsLogic.canvasModel.desc;
  }

  /// 应用场景接口
  Future<void> getSceneResource() async {
    try {
      final result = await http.post('/scene/index');
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        if (listModel.items.isNotEmpty) {
          scenarios.value = listModel.items;
          final item = listModel.items.firstWhereOrNull(
            (e) => e.id == canvalsLogic.canvasModel.sceneId,
          );
          if (item == null) {
            sceneName.value = listModel.items.first.name;
          } else {
            sceneName.value = item.name;
          }
          itemArray = scenarios.map((e) => e.name).toList();
        }
      }
    } catch (e) {
      AppLogger.error('获取场景数据失败:', e);
    }
  }

  /// 风格标签
  Future<void> getSuggestedTags() async {
    try {
      final result = await http.post('/tag/index');
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        suggestedTags.value = listModel.items;

        final bIds = canvalsLogic.canvasModel.tagData.map((e) => e.id).toSet();
        final tags = suggestedTags.where((e) => bIds.contains(e.id)).toList();
        selectedTags.assignAll(tags);
      }
    } catch (e) {
      AppLogger.error('获取场景数据失败: ', e);
    }
  }

  /// 切换标签选择状态
  void toggleTag(ScreenItemModel model) {
    if (!selectedTags.contains(model)) {
      selectedTags.add(model);
    }
  }

  /// 移除标签
  void removeTag(ScreenItemModel model) {
    selectedTags.remove(model);
  }

  /// 切换场景下拉框显示状态
  void toggleScenarioDropdown() {
    FocusManager.instance.primaryFocus?.unfocus(); // 先收起键盘
    showScenarioDropdown.value = !showScenarioDropdown.value;
  }

  /// 关闭场景下拉框
  void closeScenarioDropdown() {
    showScenarioDropdown.value = false;
  }

  /// 选择场景
  void selectScenario(String name) {
    sceneName.value = name;
    showScenarioDropdown.value = false;
  }

  /// 保存模版
  void saveTemplate() async {
    if (global.connectStatus.currentStatus == Status.none) {
      showToast("保存失败");
      return;
    }
    if (!canvalsLogic.global.isLogin) {
      SmartDialog.dismiss();
      Get.toNamed(AppRoutes.appLogin);
      return;
    }

    if (!isCanSave.value) {
      return;
    }
    isSaveTemplate.value = true;
    showLoading("保存中...");
    await zipResourceInDocuments();
  }

  /// 保存为草稿
  Future<void> saveAsDraft({bool isCanvals = false}) async {
    if (global.connectStatus.currentStatus == Status.none) {
      showToast("保存失败");
      return;
    }
    if (!canvalsLogic.global.isLogin) {
      SmartDialog.dismiss();
      Get.toNamed(AppRoutes.appLogin);
      return;
    }

    if (!isCanvals) {
      showLoading("保存中...");
    }
    isSaveTemplate.value = false;
    await DraftManager().saveCurrentCanvals();
    await zipResourceInDocuments();
  }

  /// 处理压缩包资源
  Future<void> zipResourceInDocuments() async {
    CanvasModel? model = await DraftManager().loadDraft();
    if (model == null) {
      await DraftManager().saveNoElementCanvals();
      model = await DraftManager().loadDraft();
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final sourceDir = await DirectoryManager.getDocumentsSubDirectory(
        'cavals',
      );
      final zipPath = p.join(
        docsDir.path,
        'cavals_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      // Zip 打包放到 isolate，避免阻塞 UI；失败则回退到主 isolate
      try {
        await compute(_createZipFromDirectoryInIsolate, {
          'sourcePath': sourceDir.path,
          'zipPath': zipPath,
        });
      } catch (_) {
        await ZipFile.createFromDirectory(
          sourceDir: sourceDir,
          zipFile: zipFile,
          recurseSubDirs: true,
          includeBaseDirectory: true,
        );
      }

      if (isSaveTemplate.value) {
        await _uploadZipAndImageParallel(model!, zipPath);
      } else {
        final int zipBytes = await zipFile.length(); // 压缩包大小（字节）
        final double zipKB = zipBytes / 1024;
        final draftSize =
            double.tryParse(global.userInfo.value.designDraftFileSize) ??
            0 + zipKB;
        final draftSizeLimit =
            double.tryParse(global.userInfo.value.designDraftFileSizeLimit) ??
            0;
        if (draftSize >= draftSizeLimit) {
          SmartDialog.dismiss(status: SmartStatus.loading);
          SmartDialog.dismiss();
          showDraftMemoryDialog();
        } else {
          await _uploadZipAndImageParallel(model!, zipPath);
        }
      }
    } catch (e, st) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      AppLogger.error('zipResourceInDocuments error:', e, st);
    }
  }

  /// 并行获取 zip / 图片上传 URL，再并行上传 zip 与图片，最后落库
  Future<void> _uploadZipAndImageParallel(
    CanvasModel model,
    String zipPath,
  ) async {
    if (canvalsImage == null) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast('画布截图失败');
      return;
    }
    uploadProgress.value = 0;

    try {
      // 1. 并行获取两个上传 URL
      final zipUrlFuture = _requestZipUploadUrl();
      final imageUrlFuture = _requestImageUploadUrl();
      final results = await Future.wait([zipUrlFuture, imageUrlFuture]);
      final zipOss = results[0];
      final imageOss = results[1];

      if (zipOss == null || imageOss == null) {
        SmartDialog.dismiss(status: SmartStatus.loading);
        showToast('获取资源上传地址失败');
        AppLogger.info('保存时===获取资源上传地址失败');
        return;
      }

      // 2. 并行上传 zip（流式 + 进度）与图片
      await Future.wait([
        _uploadZipFileStream(
          zipOss,
          zipPath,
          onSendProgress: (sent, total) {
            if (total > 0) uploadProgress.value = sent / total;
          },
        ),
        _uploadImageFileOnly(imageOss, canvalsImage!),
      ]);

      // 3. 落库
      if (isSaveTemplate.value) {
        await createAndUpdateTemplate(zipPath, model);
      } else {
        await createAndUpdateDraft(zipPath, model);
      }
    } catch (e) {
      AppLogger.error('上传失败', e);
      SmartDialog.dismiss(status: SmartStatus.loading);
      FileManager.deleteFileByPath(zipPath);
    } finally {
      uploadProgress.value = 0;
    }
  }

  /// 仅请求 zip 上传 URL
  Future<UploadOssModel?> _requestZipUploadUrl() async {
    final result = await http.post<UploadOssModel>(
      '/upload/generateUploadUrl',
      data: {
        "type": isSaveTemplate.value ? "design" : 'design_draft',
        "file_type": 'zip',
        "field_type": isSaveTemplate.value ? "design_zip" : 'design_draft_zip',
      },
      converter: UploadOssModel.fromJson,
    );
    if (result.code == 0 && result.data != null) return result.data;
    return null;
  }

  /// 仅请求图片上传 URL
  Future<UploadOssModel?> _requestImageUploadUrl() async {
    final result = await http.post<UploadOssModel>(
      '/upload/generateUploadUrl',
      data: {
        "type": isSaveTemplate.value ? "design" : "design_draft",
        "file_type": 'png',
        "field_type": isSaveTemplate.value ? "design_img" : "design_draft_img",
      },
      converter: UploadOssModel.fromJson,
    );
    if (result.code == 0 && result.data != null) return result.data;
    return null;
  }

  /// 流式上传 zip 到 OSS（低内存、支持进度与长超时）
  Future<void> _uploadZipFileStream(
    UploadOssModel ossModel,
    String zipPath, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
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
        sendTimeout: _uploadSendTimeout,
        headers: {Headers.contentLengthHeader: contentLength},
      ),
      useBaseUrl: false,
      isNake: true,
      onSendProgress: onSendProgress,
    );
    if (res.isSuccess || (res.code == 200)) {
      fileMemorySize = (contentLength / 1024).ceil();
      fileResourceId = ossModel.resourceId;
    } else {
      throw Exception('zip upload failed: ${res.code}');
    }
  }

  /// 仅上传图片到 OSS，并写入 imageResourceId / imageMemorySize
  Future<void> _uploadImageFileOnly(
    UploadOssModel ossModel,
    Uint8List bytes,
  ) async {
    AppLogger.info('图片资源大小---${bytes.length}');

    final mimeType = mimeTypeMap["png"] ?? "";
    final res = await http.put(
      ossModel.signUrl,
      data: bytes,
      options: Options(
        contentType: mimeType,
        sendTimeout: _uploadSendTimeout,
        headers: {Headers.contentLengthHeader: bytes.length},
      ),
      useBaseUrl: false,
      isNake: true,
    );

    if (res.isSuccess || (res.code == 200)) {
      imageMemorySize = (bytes.length / 1024).ceil();
      imageResourceId = ossModel.resourceId;
    } else {
      throw Exception('image upload failed: ${res.code}');
    }
  }

  ///创建新的保存模版
  Future<void> createAndUpdateTemplate(
    String filePath,
    CanvasModel model,
  ) async {
    try {
      final screenModel = scenarios.firstWhere(
        (e) => e.name == sceneName.value,
      );
      final sourceDir = await DirectoryManager.getDocumentsSubDirectory(
        'cavals',
      );
      final idsStr = model.elements.map((e) => e.fontId).toSet().join(',');

      if (canvalsLogic.type != PageSource.create) {
        if (canvalsLogic.isOwn == 1) {
          tempteIsNewCreate.value = false;
        }
      }

      var params = {};
      if (tempteIsNewCreate.value) {
        params = {
          "uuid": canvalsLogic.type == PageSource.create
              ? model.uuid
              : uuid.v4(),
          "edit_time": '${model.timestamp}',
          "title": titleController.text.trim(),
          "desc": descriptionController.text.trim(),
          "canvas": model.ratio,
          "canvas_size": '${model.width}:${model.height}',
          "is_clear": model.clarity,
          "scene_id": '${screenModel.id}',
          "tag_ids": selectedTags.isEmpty
              ? ''
              : selectedTags.map((e) => e.id).join(','),
          "img_id": '$imageResourceId',
          "zip_id": '$fileResourceId',
          "img_file_size": '$imageMemorySize',
          "zip_file_size": "$fileMemorySize",
          "front_ids": idsStr,
          "design_draft_id": canvalsLogic.type == PageSource.draft
              ? model.id
              : 0,
        };
      } else {
        params = {
          "id": '${model.id}',
          "edit_time": '${model.timestamp}',
          "title": titleController.text.trim(),
          "desc": descriptionController.text.trim(),
          "scene_id": '${screenModel.id}',
          "tag_ids": selectedTags.isEmpty
              ? ''
              : selectedTags.map((e) => e.id).join(','),
          "img_id": '$imageResourceId',
          "zip_id": '$fileResourceId',
          "img_file_size": '$imageMemorySize',
          "zip_file_size": "$fileMemorySize",
          "front_ids": idsStr,
        };
      }
      final result = await http.post<SaveResponse>(
        tempteIsNewCreate.value ? '/design/store' : '/design/update',
        data: params,
        converter: SaveResponse.fromJson,
      );

      if (result.code == 0 && result.data != null) {
        SmartDialog.dismiss(status: SmartStatus.loading);

        // 模版保存成功后，资源保存到本地
        await TemplateStoreManager.instance.saveOrUpdateTemplate(
          model,
          result.data!.id,
        );

        ///草稿转模版删除本地数据
        if (canvalsLogic.type == PageSource.draft) {
          await DraftStoreManager.instance.deleteDraftById(model.id);
        }
        showToast("保存成功");

        EventBusManager.share.emit(AppEventType.mineRefresh);
        if (draftIsCreate.value) {
          Get.until((route) => route.isFirst);
        } else {
          Get.back(result: true);
        }
        FileManager.deleteFileByPath(sourceDir.path);
        FileManager.deleteFileByPath(filePath);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
        showToast("保存失败");
        FileManager.deleteFileByPath(filePath);
      }
      SmartDialog.dismiss(status: SmartStatus.loading);
    } catch (e) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      showToast("保存失败");
      FileManager.deleteFileByPath(filePath);
    }
  }

  ///保存草稿
  Future<void> createAndUpdateDraft(String filePath, CanvasModel model) async {
    try {
      final sourceDir = await DirectoryManager.getDocumentsSubDirectory(
        'cavals',
      );
      final idsStr = model.elements.map((e) => e.fontId).toSet().join(',');
      if (canvalsLogic.type == PageSource.draft) {
        draftIsCreate.value = false;
      }
      var params = {};
      if (draftIsCreate.value) {
        params = {
          "uuid": canvalsLogic.type == PageSource.create
              ? model.uuid
              : uuid.v4(),
          "edit_time": '${model.timestamp}',
          "title": '',
          "desc": '',
          "canvas": model.ratio,
          "canvas_size": '${model.width}:${model.height}',
          "is_clear": model.clarity,
          "scene_id": '',
          "tag_ids": '',
          "img_id": '$imageResourceId',
          "zip_id": '$fileResourceId',
          "img_file_size": '$imageMemorySize',
          "zip_file_size": "$fileMemorySize",
          "front_ids": idsStr,
        };
      } else {
        params = {
          "id": '${model.id}',
          "edit_time": '${model.timestamp}',
          "img_id": '$imageResourceId',
          "zip_id": '$fileResourceId',
          "img_file_size": '$imageMemorySize',
          "zip_file_size": "$fileMemorySize",
          "front_ids": idsStr,
        };
      }

      final result = await http.post<SaveResponse>(
        draftIsCreate.value ? '/design/draft/store' : '/design/draft/update',
        data: params,
        converter: SaveResponse.fromJson,
      );

      if (result.code == 0 && result.data != null) {
        if (draftIsCreate.value) {
          await DraftStoreManager.instance.saveOrUpdateDraft(
            model,
            result.data!.id,
          );
        } else {
          await DraftStoreManager.instance.saveOrUpdateDraft(model, model.id);
        }

        SmartDialog.dismiss(status: SmartStatus.loading);
        showToast("保存成功");

        EventBusManager.share.emit(AppEventType.mineRefresh);

        if (draftIsCreate.value) {
          Get.until((route) => route.isFirst);
        } else {
          Get.back(result: true);
        }

        FileManager.deleteFileByPath(sourceDir.path);
        FileManager.deleteFileByPath(filePath);
      } else {
        FileManager.deleteFileByPath(filePath);

        AppLogger.info('草稿保存失败====${result.code}');
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      AppLogger.error('草稿保存失败', e);
      FileManager.deleteFileByPath(filePath);
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 显示是否保存为草稿
  void showDraftMemoryDialog() {
    final textWidget = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 16.w,
          color: "#434343".color,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: '您的草稿存储空间已满，请\n先去'),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GradientText(
              '"我的草稿"',
              style: TextStyle(fontSize: 16.w, fontWeight: FontWeight.w500),
              colors: ["#8556FF".color, "#3691FF".color.withValues(alpha: 0.5)],
              stops: [0.7, 1.0],
            ),
          ),
          TextSpan(text: '页面整理保存的\n草稿，才能继续开始新的设计'),
        ],
      ),
    );

    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "存储空间已满",
        subTitleWidget: textWidget,
        sureTitle: "跳转我的草稿",
        sureAction: () {
          SmartDialog.dismiss();
          Get.toNamed(AppRoutes.draft);
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

/*
草稿：
  * 保存模版： 新建
  * 保存草稿： 更新

其它的要区分是否是自己
  别人的都是 新建
  自己的保存模版都是更新，保存草稿都是新建
*/
