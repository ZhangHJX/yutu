import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/ui/canvas/pages/canvals/canvals_controller.dart';
import 'dart:typed_data';
import 'package:voicetemplate/ui/model/index.dart';
import 'package:voicetemplate/file/index.dart';
import 'package:voicetemplate/ui/canvas/model/index.dart';
import 'package:voicetemplate/ui/canvas/draft/index.dart';
import './model/save_response.dart';
import 'template/template_manager.dart';

class SaveLogic extends GetxController {
  // 获取画布控制器
  final canvalsLogic = Get.find<CanvalsController>();

  /// 画布的图片信息
  late final Uint8List? canvalsImage;
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

  ///风格标签
  final suggestedTags = <ScreenItemModel>[].obs;
  final selectedTags = <ScreenItemModel>[].obs;

  final isSaveActiion = false.obs;

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    debugPrint("-保存模版----onClose------");
    super.onClose();
  }

  @override
  void onInit() async {
    super.onInit();
    await getSceneResource();
    await getSuggestedTags();
  }

  /// 应用场景接口
  Future<void> getSceneResource() async {
    try {
      final result = await http.post('/scene/index', showErrorToast: false);
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        if (listModel.items.isNotEmpty) {
          scenarios.value = listModel.items;
          sceneName.value = listModel.items.first.name;
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
      final result = await http.post('/tag/index', showErrorToast: false);
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        suggestedTags.value = listModel.items;
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
    if (titleController.text.trim().isEmpty) {
      showToast('请输入模版标题');
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      showToast('请输入模版描述');
      return;
    }
    if (sceneName.isEmpty) {
      SmartDialog.showToast('应用场景不能为空');
      return;
    }
    if (selectedTags.isEmpty) {
      SmartDialog.showToast('请至少选择一个风格标签');
      return;
    }

    final canvalsModel = await DraftManager().loadDraft();
    if (canvalsModel == null) {
      showToast('画布信息不存在');
      return;
    }
    if (canvalsImage == null) {
      showToast('画布截图未成功');
      return;
    }
    isSaveActiion.value = true;
    await getImageRemotePath(canvalsModel, "保存中...");
  }

  /// 保存为草稿
  Future<void> saveAsDraft() async {
    final canvalsModel = await DraftManager().loadDraft();
    if (canvalsModel == null) {
      showToast('画布信息不存在');
      return;
    }
    isSaveActiion.value = false;
    await getImageRemotePath(canvalsModel, "保存中...");
  }

  /// 获取图片下载地址
  Future<void> getImageRemotePath(CanvasModel model, String tips) async {
    showLoading(tips);
    try {
      // 获取图片的的上传路径
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {
          "type": isSaveActiion.value ? "design" : "design_draft",
          "file_type": 'png',
          "field_type": isSaveActiion.value ? "design_img" : "design_draft_img",
        },
        converter: UploadOssModel.fromJson,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        await uploadImageFile(result.data!, canvalsImage!, model);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('获取图片信息报错---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 上传图片到服务器
  Future<void> uploadImageFile(
    UploadOssModel ossModel,
    Uint8List bytes,
    CanvasModel model,
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
        showErrorToast: false,
        isNake: true,
      );

      /// 上传成功
      if (res.isSuccess) {
        imageMemorySize = (bytes.length / 1024).ceil(); // 向上取整
        imageResourceId = ossModel.resourceId;
        await handleZipResource(model);
      } else {
        debugPrint('图片上传失败----${res.code}');
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('图片上传失败---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 获取压缩包上传地址
  Future<void> handleZipResource(CanvasModel model) async {
    final result = await http.post<UploadOssModel>(
      '/upload/generateUploadUrl',
      data: {
        "type": isSaveActiion.value ? "design" : 'design_draft',
        "file_type": 'zip',
        "field_type": isSaveActiion.value ? "design_zip" : 'design_draft_zip',
      },
      converter: UploadOssModel.fromJson,
      showErrorToast: true,
    );
    if (result.code == 0 && result.data != null) {
      await uploadZipFile(result.data!, model);
    }
  }

  /// 处理压缩包资源
  Future<String> zipCavalsInDocuments() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final sourceDir = await DirectoryManager.getDocumentsSubDirectory('cavals');
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
    return zipFile.path; // ✅ 压缩后的zip完整路径
  }

  /// 上传资源压缩包到服务器
  Future<void> uploadZipFile(UploadOssModel ossModel, CanvasModel model) async {
    final zipPath = await zipCavalsInDocuments();
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
        showErrorToast: false,
        isNake: true,
      );

      /// 上传成功
      if (res.isSuccess) {
        fileMemorySize = (bytes.length / 1024).ceil(); // 向上取整
        fileResourceId = ossModel.resourceId;
        if (isSaveActiion.value) {
          await createAndUpdateTemplate(zipPath, model);
        } else {
          await createAndUpdateDraft(zipPath, model);
        }
      } else {
        debugPrint('文件上传失败"');
        FileManager.deleteFileByPath(zipPath);
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('图片上传失败---$e');
      FileManager.deleteFileByPath(zipPath);
      SmartDialog.dismiss(status: SmartStatus.loading);
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

      var params = {
        "uuid": model.uuid,
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
      };

      if (model.id > 0) {
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
        model.id > 0 ? '/design/update' : '/design/store',
        data: params,
        converter: SaveResponse.fromJson,
        showErrorToast: true,
      );
      debugPrint("===模版保存是否成功====${result.code}=====");
      if (result.code == 0 && result.data != null) {
        // 模版保存成功后，资源保存到本地
        await TemplateManager.instance.saveTemplateFromSaveFlow(
          result.data!.id,
          model.timestamp,
        );

        Get.back(result: true);
        FileManager.deleteFileByPath(sourceDir.path);
        FileManager.deleteFileByPath(filePath);
      } else {
        FileManager.deleteFileByPath(filePath);
      }
      SmartDialog.dismiss(status: SmartStatus.loading);
    } catch (e) {
      FileManager.deleteFileByPath(filePath);
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  ///保存草稿
  Future<void> createAndUpdateDraft(String filePath, CanvasModel model) async {
    try {
      final sourceDir = await DirectoryManager.getDocumentsSubDirectory(
        'cavals',
      );
      final idsStr = model.elements.map((e) => e.fontId).toSet().join(',');

      var params = {
        "uuid": model.uuid,
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
      if (model.id > 0) {
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
        model.id > 0 ? '/design/draft/update' : '/design/draft/store',
        data: params,
        showErrorToast: true,
        converter: SaveResponse.fromJson,
      );

      if (result.code == 0 && result.data != null) {
        final success = await DraftStoreManager.instance.saveOrUpdateDraft(
          model,
          result.data!.id,
        );
        if (!success) {
          debugPrint('===草稿保存或更新失败===');
        } else {
          debugPrint('===草稿保存或更新成功===');
        }
        Get.back(result: true);
        FileManager.deleteFileByPath(sourceDir.path);
        FileManager.deleteFileByPath(filePath);
      } else {
        FileManager.deleteFileByPath(filePath);
        debugPrint('草稿保存失败====${result.code}');
      }
      SmartDialog.dismiss(status: SmartStatus.loading);
    } catch (e) {
      debugPrint('草稿保存失败--$e');
      FileManager.deleteFileByPath(filePath);
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }
}
