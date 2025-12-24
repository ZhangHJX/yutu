import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/ui/canvas/pages/canvals/canvals_controller.dart';
import 'dart:typed_data';
import 'package:voicetemplate/ui/model/index.dart';

class SaveLogic extends GetxController {
  // 创建一个回调
  Function()? handleImageCallBack;

  // 获取画布控制器
  final canvalsLogic = Get.find<CanvalsController>();

  /// 画布的图片信息
  late final Uint8List? canvalsImage;
  int imageMemorySize = 0; // 单位字节 kb
  int imageResourceId = 0; // 图片的id

  /// 本地文件相关信息
  int fileMemorySize = 0; // 单位字节 kb
  int fileResourceId = 0; // 文件的id

  //
  final tempTitle = ''.obs;
  final descript = ''.obs;

  // 文本控制器
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final scenarioDropdownKey = GlobalKey();

  /// 展开和关闭弹框
  final showScenarioDropdown = false.obs;

  ///应用场景
  final selectedScenario = '房间宣传'.obs;

  ///风格标签
  final selectedTags = <String>[].obs;

  // 常量数据
  List<String> scenarios = [
    '房间宣传',
    '活动公告',
    '歌单展示',
    '名片模板',
    '节日氛围',
    '冠歌卡',
    '冠名卡',
  ];

  final List<String> suggestedTags = [
    '二次元',
    '恋爱',
    '简约',
    '炫彩',
    '可爱',
    '赛博',
    '复古',
  ];

  @override
  void onClose() {
    // titleController.dispose();
    // descriptionController.dispose();
    debugPrint("-保存模版----onClose------");
    super.onClose();
  }

  /// 切换标签选择状态
  void toggleTag(String tag) {
    if (!selectedTags.contains(tag)) {
      selectedTags.add(tag);
    }
  }

  /// 移除标签
  void removeTag(String tag) {
    debugPrint("--移除标签---");
    selectedTags.remove(tag);
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
  void selectScenario(String scenario) {
    selectedScenario.value = scenario;
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
    // 获取图片的的上传路径
    final result = await http.post<UploadOssModel>(
      '/upload/generateUploadUrl',
      data: {
        "type": "material_user",
        "file_type": 'png',
        "field_type": "material_user_img",
      },
      converter: UploadOssModel.fromJson,
      showErrorToast: false,
      withToken: true,
    );
    if (result.code == 0 && result.data != null) {
      await uploadImageFile(result.data!, canvalsImage!);
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
      data: {
        "type": "material_user",
        "file_type": 'zip',
        "field_type": "material_user_img",
      },
      converter: UploadOssModel.fromJson,
      showErrorToast: false,
      withToken: true,
    );
  }

  /// 上传资源压缩包到服务器
  Future<void> uploadZipFile(UploadOssModel ossModel, Uint8List bytes) async {
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
        // await requestImage(ossModel.resourceId, fileSize, width, height);
      } else {
        showToast("文件上传失败");
        debugPrint('文件上传失败"');
        SmartDialog.dismiss(status: SmartStatus.loading);
      }
    } catch (e) {
      showToast("文件上传失败");
      debugPrint('图片上传失败---$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  Future<void> saveTempCavals(UploadOssModel ossModel, Uint8List bytes) async {
    try {
      final canvalsModel = canvalsLogic.buildSnapshot();
      final result = await http.post(
        '/design/store',
        data: {
          "uuid": canvalsModel?.id,
          "edit_time": '${canvalsModel?.timestamp}',
          "title": tempTitle.value,
          "desc": descript.value,
          "canvas": canvalsModel?.ratio,
          "canvas_size": '${canvalsModel?.width}:${canvalsModel?.height}',
          "is_clear": canvalsModel?.clarity,
          "scene_id": '1.0',
          "tag_ids": ['1.0', '1.0', '1.0'],
          "img_id": '$imageResourceId',
          "zip_id": '$fileResourceId',
          "img_file_size": '$imageMemorySize',
          "zip_file_size": "$fileMemorySize",
        },
        showErrorToast: false,
      );
      debugPrint('========>>>把获取到的信息传给后台=${result.code}==');
      if (result.code == 0) {
      } else {
        showToast("模版保存失败");
        debugPrint('模版保存失败');
      }
      SmartDialog.dismiss(status: SmartStatus.loading);
    } catch (e) {
      showToast("模版保存失败");
      debugPrint('模版保存失败--$e');
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  /// 保存为草稿
  void saveAsDraft() {
    debugPrint("保存为草稿");
  }
}
