import 'dart:io';

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:voicetemplate/ui/canvas/pages/canvals/canvals_controller.dart';
import 'dart:typed_data';
import 'package:voicetemplate/ui/model/index.dart';
import 'package:voicetemplate/file/index.dart';
import './model/screen_model.dart';

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
  final showScenarioDropdown = false.obs;
  RxString sceneName = ''.obs;

  ///风格标签
  final suggestedTags = <ScreenItemModel>[].obs;
  final selectedTags = <ScreenItemModel>[].obs;

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
      final result = await http.post(
        '/scene/index',
        withToken: true,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        final listModel = ScreenModel.fromJson(result.data);
        scenarios.value = listModel.items;
        if (listModel.items.isNotEmpty) {
          sceneName.value = listModel.items.first.name;
        }
      }
    } catch (e) {
      debugPrint('获取场景数据失败: $e');
    }
  }

  /// 风格标签
  Future<void> getSuggestedTags() async {
    try {
      final result = await http.post(
        '/tag/index',
        withToken: true,
        showErrorToast: false,
      );
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

    final canvalsModel = canvalsLogic.buildSnapshot();
    if (canvalsModel == null) {
      showToast('画布信息不存在');
      return;
    }
    if (canvalsImage == null) {
      showToast('画布截图未成功');
      return;
    }
    showLoading("上传中");
    try {
      // 获取图片的的上传路径
      final result = await http.post<UploadOssModel>(
        '/upload/generateUploadUrl',
        data: {
          "type": "design",
          "file_type": 'png',
          "field_type": "design_img",
        },
        converter: UploadOssModel.fromJson,
        showErrorToast: false,
        withToken: true,
      );
      if (result.code == 0 && result.data != null) {
        await uploadImageFile(result.data!, canvalsImage!);
      } else {
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      debugPrint('获取图片信息报错---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 上传图片到服务器
  Future<void> uploadImageFile(UploadOssModel ossModel, Uint8List bytes) async {
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
        withToken: true,
        showErrorToast: false,
        isNake: true,
      );

      /// 上传成功
      if (res.isSuccess) {
        imageMemorySize = (bytes.length / 1024).ceil(); // 向上取整
        imageResourceId = ossModel.resourceId;
        await handleZipResource();
      } else {
        debugPrint('图片上传失败----${res.code}');
        showToast("保存失败");
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      showToast("保存失败");
      debugPrint('图片上传失败---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 处理压缩包资源
  Future<void> handleZipResource() async {
    final result = await http.post<UploadOssModel>(
      '/upload/generateUploadUrl',
      data: {"type": "design", "file_type": 'zip', "field_type": "design_zip"},
      converter: UploadOssModel.fromJson,
      showErrorToast: false,
      withToken: true,
    );
    if (result.code == 0 && result.data != null) {
      await uploadZipFile(result.data!);
    }
  }

  /// 上传资源压缩包到服务器
  Future<void> uploadZipFile(UploadOssModel ossModel) async {
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
        withToken: true,
        showErrorToast: false,
        isNake: true,
      );

      /// 上传成功
      if (res.isSuccess) {
        fileMemorySize = (bytes.length / 1024).ceil(); // 向上取整
        fileResourceId = ossModel.resourceId;
        await saveTempCavals(zipPath);
      } else {
        showToast("文件上传失败");
        debugPrint('文件上传失败"');
        FileManager.deleteFileByPath(zipPath);
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      showToast("文件上传失败");
      debugPrint('图片上传失败---$e');
      FileManager.deleteFileByPath(zipPath);
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  Future<void> saveTempCavals(String filePath) async {
    try {
      final screenModel = scenarios.firstWhere(
        (e) => e.name == sceneName.value,
      );
      final canvalsModel = canvalsLogic.buildSnapshot();
      final result = await http.post(
        '/design/store',
        data: {
          "uuid": canvalsModel?.id,
          "edit_time": '${canvalsModel?.timestamp}',
          "title": titleController.text.trim(),
          "desc": descriptionController.text.trim(),
          "canvas": canvalsModel?.ratio,
          "canvas_size": '${canvalsModel?.width}:${canvalsModel?.height}',
          "is_clear": canvalsModel?.clarity,
          "scene_id": '${screenModel.id}',
          "tag_ids": selectedTags.isEmpty
              ? ''
              : selectedTags.map((e) => e.id).join(','),
          "img_id": '$imageResourceId',
          "zip_id": '$fileResourceId',
          "img_file_size": '$imageMemorySize',
          "zip_file_size": "$fileMemorySize",
        },
        showErrorToast: false,
        withToken: true,
      );
      if (result.code == 0) {
        showToast("模版保存成功");
        Get.back();
        FileManager.deleteFileByPath(filePath);
      } else {
        showToast("模版保存失败");
        FileManager.deleteFileByPath(filePath);
        debugPrint('模版保存失败');
      }
      SmartDialog.dismiss(status: SmartStatus.loading);
    } catch (e) {
      showToast("模版保存失败");
      debugPrint('模版保存失败--$e');
      FileManager.deleteFileByPath(filePath);
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

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

  /// 保存为草稿
  void saveAsDraft() {
    debugPrint("保存为草稿");
  }
}
