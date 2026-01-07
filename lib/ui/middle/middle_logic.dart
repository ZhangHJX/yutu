import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'model/middle_model.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'package:voicetemplate/app/routes/index.dart';
import 'download/download_service.dart';
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
    switch (source) {
      case PageSource.home:
        return '/homePage/read';
      case PageSource.search:
        return '/homePage/search/read';
      case PageSource.design:
        return '/design/read';
      case PageSource.draft:
        return '/design/draft/read';
      case PageSource.favorite:
        return '/user/favorite/read';
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
    switch (source) {
      case PageSource.home:
        return isFavorite
            ? '/homePage/favorite-store'
            : '/homePage/favorite-destroy';
      case PageSource.search:
        return isFavorite
            ? '/homePage/search/favorite-store'
            : '/homePage/search/favorite-destroy';
      case PageSource.design:
        return isFavorite
            ? '/design/favorite-store'
            : '/design/favorite-destroy';
      case PageSource.draft:
        return '';
      case PageSource.favorite:
        return '';
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

      // 2. 根据来源类型处理资源文件
      String resourcePath;
      if (type == PageSource.draft) {
        // 草稿场景：检查数据库，如果有数据且时间戳匹配，直接使用本地文件
        final (exists, timestampMatches) = await DownloadService.instance
            .checkDraftResourceExists(model.id, model.editTime);

        if (exists && timestampMatches) {
          // 时间戳匹配，直接使用本地文件
          debugPrint('MiddleLogic: 草稿 ${model.id} 时间戳匹配，使用本地文件');
          // 获取草稿资源路径
          final supportDir = await DirectoryManager.getSupportDirectory();
          resourcePath = p.join(
            supportDir.path,
            'sqflite_draft',
            '${model.id}',
          );
        } else {
          // 需要下载
          resourcePath = await DownloadService.instance.downloadDraftResource(
            model.recourcesUrl,
            model.id,
            model.editTime,
            onProgress: (progress) {
              debugPrint(
                '资源文件下载进度: ${(50 + progress * 50).toStringAsFixed(1)}%',
              );
            },
            shouldCancel: () => _isCancelled,
          );
        }
      } else {
        // 模板场景：检查文件是否存在
        final resourceExists = await DownloadService.instance
            .checkTemplateResourceExists(model.id, model.editTime);

        if (resourceExists) {
          // 文件已存在，直接使用
          debugPrint(
            'MiddleLogic: 模板资源文件 ${model.id}_${model.editTime} 已存在，使用本地文件',
          );
          final templatesDir = await DirectoryManager.getSupportSubDirectory(
            'templates',
          );
          resourcePath = p.join(
            templatesDir.path,
            '${model.id}_${model.editTime}',
          );
        } else {
          // 需要下载
          resourcePath = await DownloadService.instance
              .downloadTemplateResource(
                model.recourcesUrl,
                model.id,
                model.editTime,
                onProgress: (progress) {
                  debugPrint(
                    '资源文件下载进度: ${(50 + progress * 50).toStringAsFixed(1)}%',
                  );
                },
                shouldCancel: () => _isCancelled,
              );
        }
      }

      // 检查是否已取消
      if (_isCancelled) {
        SmartDialog.dismiss();
        return;
      }

      debugPrint('MiddleLogic: 准备获取解压后的数据文件夹: $resourcePath');

      // 3. 将资源文件复制到 Documents/cavals 目录
      await DownloadService.instance.copyResourceToCavals(resourcePath);

      // 4. 加载草稿并进入画布编辑器
      final canvalsModel = await DraftManager().loadDraft();
      if (canvalsModel == null) {
        SmartDialog.dismiss();
        return;
      }
      // 根据当前屏幕重新计算画布矩阵
      canvalsModel.getMatrix4();
      SmartDialog.dismiss();
      Get.toNamed(AppRoutes.canvalsPage, arguments: canvalsModel);
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
}
