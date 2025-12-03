import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../widgets/index.dart';
import '../canvas/draft/index.dart';

class HomeLogic extends GetxController {
  @override
  void onInit() {
    super.onInit();
    showDraftDialog();
  }

  void showDraftDialog() async {
    final isHave = await DraftManager().hasDraft();
    if (isHave) {
      SmartDialog.show(
        builder: (context) => ConfirmPopWidget(
          title: "继续编辑",
          subTitle: "您上次编辑的草稿未正常保存，是\n否返回编辑器继续编辑？",
          cancelAction: () {
            DraftManager().deleteDraft();
          },
          sureAction: () {},
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
