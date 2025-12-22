import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../widgets/index.dart';
import '../canvas/draft/index.dart';
import '../../app/routes/index.dart';
import '../utils/file/canvals_file_manager.dart';
import '../canvas/fonts/font_manager.dart';

class HomeLogic extends GetxController {
  // Tab 索引
  final selectedTabIndex = 0.obs;

  // Tab 列表
  final tabs = ['全部', '二次元', '恋爱', '简约', '炫彩', '海报'].obs;

  // 切换 tab
  void switchTab(int index) {
    selectedTabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    showDraftDialog();
  }

  @override
  void onReady() {
    FontManager.to.initFromDisk();
    super.onReady();
  }

  void showDraftDialog() async {
    final isHave = await DraftManager().hasDraft();
    if (isHave) {
      // 预初始化图片目录，确保后续可以通过文件名快速构造完整路径
      await CanvalsFileManager.getImagesDirectory();

      SmartDialog.show(
        builder: (context) => ConfirmPopWidget(
          title: "继续编辑",
          subTitle: "您上次编辑的草稿未正常保存，是\n否返回编辑器继续编辑？",
          cancelAction: () {
            DraftManager().deleteDraft();
          },
          sureAction: () {
            // 异步加载草稿并跳转到画布页面
            () async {
              final draft = await DraftManager().loadDraft();
              if (draft == null) {
                SmartDialog.dismiss();
                return;
              }

              // 根据当前屏幕重新计算画布矩阵
              draft.getMatrix4();

              SmartDialog.dismiss();
              Get.toNamed(AppRoutes.canvalsPage, arguments: draft);
            }();
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
}
