import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/pages/canvas/pages/canvals/canvals_controller.dart';
import 'dart:typed_data';
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

    // final hasDescription = descriptionController.text.trim().isNotEmpty;
    // final canSave = hasTitle && hasDescription && hasScene && hasTags;
    // final hasTags = selectedTags.isNotEmpty;

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
      debugPrint('获取场景数据失败: $e');
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
      debugPrint('获取场景数据失败: $e');
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
    debugPrint("--移除标签---");
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
    global.connectStatus.onStatusChanged.listen((status) {
      if (status == NetworkStatus.none) {
        showToast("保存失败");
        return;
      }
    });
    if (!isCanSave.value) {
      return;
    }
    isSaveTemplate.value = true;
    showLoading("保存中...");
    await zipResourceInDocuments();
  }

  /// 保存为草稿
  Future<void> saveAsDraft({bool isCanvals = false}) async {
    global.connectStatus.onStatusChanged.listen((status) {
      if (status == NetworkStatus.none) {
        showToast("保存失败");
        return;
      }
    });

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
      await ZipFile.createFromDirectory(
        sourceDir: sourceDir,
        zipFile: zipFile,
        recurseSubDirs: true,
        includeBaseDirectory: true,
      );

      if (isSaveTemplate.value) {
        getZipResource(model!, zipFile.path);
      } else {
        final int zipBytes = await zipFile.length(); // 压缩包大小（字节）
        final double zipKB = zipBytes / 1024;

        final draftSize =
            double.tryParse(global.userInfo.value.designDraftFileSize) ??
            0 + zipKB;
        final draftLimit =
            double.tryParse(global.userInfo.value.designDraftFileSizeLimit) ??
            0;
        if (draftSize >= draftLimit) {
          SmartDialog.dismiss(status: SmartStatus.loading);
          SmartDialog.dismiss();
          showDraftMemoryDialog();
        } else {
          getZipResource(model!, zipFile.path);
        }
      }
    } catch (e, st) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      debugPrint('zipResourceInDocuments error: $e\n$st');
    }
  }

  /// 获取压缩包上传地址
  Future<void> getZipResource(CanvasModel model, String zipPath) async {
    try {
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {
          "type": isSaveTemplate.value ? "design" : 'design_draft',
          "file_type": 'zip',
          "field_type": isSaveTemplate.value
              ? "design_zip"
              : 'design_draft_zip',
        },
        converter: UploadOssModel.fromJson,
      );
      if (result.code == 0 && result.data != null) {
        await uploadZipFile(result.data!, model, zipPath);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 上传资源压缩包到服务器
  Future<void> uploadZipFile(
    UploadOssModel ossModel,
    CanvasModel model,
    String zipPath,
  ) async {
    final file = File(zipPath);
    final bytes = await file.readAsBytes();
    try {
      String mimeType = mimeTypeMap["zip"] ?? "";
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

      /// 上传成功
      if (res.isSuccess || (res.code == 200)) {
        fileMemorySize = (bytes.length / 1024).ceil(); // 向上取整
        fileResourceId = ossModel.resourceId;
        getImageRemotePath(model, zipPath);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
        FileManager.deleteFileByPath(zipPath);
      }
    } catch (e) {
      debugPrint('图片上传失败---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
      FileManager.deleteFileByPath(zipPath);
    }
  }

  /// 获取图片下载地址
  Future<void> getImageRemotePath(CanvasModel model, String zipPath) async {
    try {
      // 获取图片的的上传路径
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {
          "type": isSaveTemplate.value ? "design" : "design_draft",
          "file_type": 'png',
          "field_type": isSaveTemplate.value
              ? "design_img"
              : "design_draft_img",
        },
        converter: UploadOssModel.fromJson,
      );
      if (result.code == 0 && result.data != null) {
        if (canvalsImage == null) {
          showToast('画布截图失败');
          return;
        }
        await uploadImageFile(result.data!, canvalsImage!, model, zipPath);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('获取图片信息报错---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
      FileManager.deleteFileByPath(zipPath);
    }
  }

  /// 上传图片到服务器
  Future<void> uploadImageFile(
    UploadOssModel ossModel,
    Uint8List bytes,
    CanvasModel model,
    String zipPath,
  ) async {
    try {
      String mimeType = mimeTypeMap["png"] ?? "";
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

      /// 上传成功
      if (res.isSuccess || (res.code == 200)) {
        imageMemorySize = (bytes.length / 1024).ceil(); // 向上取整
        imageResourceId = ossModel.resourceId;
        if (isSaveTemplate.value) {
          await createAndUpdateTemplate(zipPath, model);
        } else {
          await createAndUpdateDraft(zipPath, model);
        }
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('图片上传失败---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
      FileManager.deleteFileByPath(zipPath);
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

      debugPrint("===模版保存是否成功====$params=====");

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
        debugPrint('草稿保存失败====${result.code}');
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('草稿保存失败--$e');
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
