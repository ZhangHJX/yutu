import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'model/middle_model.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'package:voicetemplate/app/routes/index.dart';
import 'download_service.dart';
import 'middle_loading.dart';
import 'package:voicetemplate/file/index.dart';
import 'package:voicetemplate/ui/canvas/draft/index.dart';

class MiddleLogic extends GetxController {
  final args = Get.arguments as Map<String, dynamic>;
  int get itemId => args['id'] as int;
  PageSource get type => args['type'] as PageSource;

  final middleInfo = Rxn<MiddleModel>();

  String get imgUrl =>
      '${middleInfo.value?.originalImage}${middleInfo.value?.thumbnail}';

  final isFavorite = 0.obs;

  List<TagItemModel> get tagArray => middleInfo.value?.tagData ?? [];

  /// 取消标志，用于取消正在进行的下载
  bool _isCancelled = false;

  @override
  void onInit() {
    super.onInit();
    getMidelDetailData();
  }

  /// 加载中间页的页面
  Future<void> getMidelDetailData() async {
    await getMiddleData();
  }

  Future<void> getMiddleData() async {
    try {
      debugPrint("==getMiddleData==${getMiddleUrlPath(type)}=======");

      final result = await http.post(
        getMiddleUrlPath(type),
        data: {"id": itemId},
        converter: MiddleModel.fromJson,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        middleInfo.value = result.data;
        isFavorite.value = result.data!.isFavorite;
      }
    } catch (e) {
      debugPrint('获取详情页数据失败: $e');
    }
  }

  String getMiddleUrlPath(PageSource source) {
    if (source == PageSource.home) {
      return '/homePage/read';
    } else {
      return '/homePage/search/read';
    }
  }

  /// 收藏事件处理
  Future<void> clickFavoriteEvent(bool shouldFavorite) async {
    try {
      final result = await http.post(
        getFavoriteUrlPath(type, shouldFavorite),
        data: {"link_id": itemId},
        showErrorToast: false,
      );
      if (result.code == 0) {
        // 更新 isFavorite 状态
        final newFavoriteStatus = shouldFavorite ? 1 : 0;
        isFavorite.value = newFavoriteStatus;
        // 同步更新 middleInfo 中的 isFavorite
        if (middleInfo.value != null) {
          middleInfo.value = middleInfo.value!.copyWith(
            isFavorite: newFavoriteStatus,
          );
        }
      }
    } catch (e) {
      debugPrint('获取详情页数据失败: $e');
    }
  }

  /// 取消收藏事件
  void favoriteEventDialog() {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "取消收藏",
        subTitle: "是否确认取消收藏该模版",
        sureAction: () => clickFavoriteEvent(false),
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

  String getFavoriteUrlPath(PageSource source, bool isFavorite) {
    if (source == PageSource.home) {
      return isFavorite
          ? '/homePage/favorite-store'
          : '/homePage/favorite-destroy';
    } else {
      return isFavorite
          ? '/homePage/search/favorite-store'
          : '/homePage/search/favorite-destroy';
    }
  }

  /// 立即使用按钮点击处理
  Future<void> handleImmediatelyUse() async {
    final model = middleInfo.value;
    if (model == null) {
      showToast('模板信息不存在');
      return;
    }

    // 重置取消标志
    _isCancelled = false;

    try {
      // 显示加载对话框
      showLoadingDialog();

      // 1. 检查并下载字体文件
      await DownloadService.instance.downloadFontsIfNeeded(
        model.frontData,
        onProgress: (progress) {
          debugPrint('字体下载进度: ${(progress * 50).toStringAsFixed(1)}%');
        },
        shouldCancel: () => _isCancelled,
      );

      // 检查是否已取消
      if (_isCancelled) {
        SmartDialog.dismiss();
        return;
      }

      // 2. 检查并下载资源文件
      final resourceExists = await DownloadService.instance
          .checkResourceFileExists(model.id, model.editTime);

      if (!resourceExists) {
        await DownloadService.instance.downloadResourceFile(
          model.recourcesUrl,
          model.id,
          model.editTime,
          onProgress: (progress) {
            debugPrint('资源文件下载进度: ${(50 + progress * 50).toStringAsFixed(1)}%');
          },
          shouldCancel: () => _isCancelled,
        );
      }

      // 检查是否已取消
      if (_isCancelled) {
        SmartDialog.dismiss();
        return;
      }

      // 3. 获取解压后的资源文件路径
      final resourcePath = await DownloadService.instance.getResourceFilePath(
        model.id,
        model.editTime,
      );

      if (resourcePath == null) {
        SmartDialog.dismiss();
        return;
      }

      debugPrint('准备获取解压后的数据文件夹:===$resourcePath ');

      // 4. 将解压后的文件移动到 Documents 目录下并改名为 cavals
      await _moveResourceToCavals(resourcePath);

      final draft = await DraftManager().loadDraft();
      if (draft == null) {
        SmartDialog.dismiss();
        return;
      }
      // 根据当前屏幕重新计算画布矩阵
      draft.getMatrix4();
      SmartDialog.dismiss();
      Get.toNamed(AppRoutes.canvalsPage, arguments: draft);
    } catch (e) {
      SmartDialog.dismiss();
      debugPrint('准备模板失败: $e');

      // 如果是取消操作，不显示错误提示
      if (_isCancelled || e.toString().contains('取消')) {
        return;
      }

      showToast('准备模板失败，请重试');
    }
  }

  /// 服务端没有保存的相关的草稿
  void showLoadingDialog() {
    SmartDialog.show(
      builder: (context) => MiddleLoadingWidget(
        cancelAction: () {
          _handleCancelDownload();
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

  /// 处理取消下载
  Future<void> _handleCancelDownload() async {
    _isCancelled = true;
    debugPrint('MiddleLogic: 用户取消下载');

    try {
      // 取消所有正在进行的下载（字体和资源）
      await DownloadService.instance.cancelAllDownloads();
    } catch (e) {
      debugPrint('MiddleLogic: 取消下载失败: $e');
    }

    SmartDialog.dismiss();
    showToast('已取消下载');
  }

  /// 将解压后的资源文件移动到 Documents 目录下并改名为 cavals
  /// 将 sourceDir 目录下的 cavals 文件夹复制到 Documents 下
  Future<void> _moveResourceToCavals(String sourcePath) async {
    try {
      final sourceDir = Directory(sourcePath);
      if (!await sourceDir.exists()) {
        debugPrint('MiddleLogic: 源目录不存在: $sourcePath');
        return;
      }

      // 查找 sourceDir 目录下的 cavals 文件夹
      final sourceCavalsDir = Directory(p.join(sourceDir.path, 'cavals'));
      if (!await sourceCavalsDir.exists()) {
        debugPrint('MiddleLogic: 源目录下不存在 cavals 文件夹: ${sourceCavalsDir.path}');
        return;
      }

      // 获取 Documents/cavals 目录
      final documentsDir = await DirectoryManager.getDocumentsDirectory();
      final targetCavalsDir = Directory(p.join(documentsDir.path, 'cavals'));

      // 如果目标目录已存在，先删除（使用 FileManager）
      if (await targetCavalsDir.exists()) {
        await FileManager.deleteDirectory(
          targetCavalsDir,
          deleteDirectory: true,
        );
      }

      // 将 sourceDir 下的 cavals 文件夹复制到 Documents 下
      await _copyDirectoryRecursive(sourceCavalsDir, targetCavalsDir);

      debugPrint(
        'MiddleLogic: cavals 文件夹已复制到 Documents: ${targetCavalsDir.path}',
      );
    } catch (e) {
      debugPrint('MiddleLogic: 复制 cavals 文件夹失败: $e');
      rethrow;
    }
  }

  /// 递归复制目录及其所有内容
  Future<void> _copyDirectoryRecursive(
    Directory source,
    Directory destination,
  ) async {
    // 确保目标目录存在
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    // 遍历源目录中的所有内容
    await for (final entity in source.list(recursive: false)) {
      final fileName = p.basename(entity.path);
      final targetPath = p.join(destination.path, fileName);

      if (entity is File) {
        // 复制文件
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        // 递归复制子目录
        final targetSubDir = Directory(targetPath);
        await _copyDirectoryRecursive(entity, targetSubDir);
      }
    }
  }
}
