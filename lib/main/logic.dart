import 'package:common/common.dart';
import 'package:flutter/material.dart';

import 'package:voicetemplate/stores/global.dart';
import '../pages/home/home_page.dart';
import '../pages/mine/mine_main_page.dart';
import '../pages/mine/mine_logic.dart';
import 'package:voicetemplate/pages/canvas/pages/create/create_canvals_page.dart';
import '../core/index.dart';

class MainLogic extends GetxController {
  final global = Get.put(GlobalLogic(), permanent: true);

  final pages = List<Widget?>.filled(2, null).obs;

  final homeFrames = <String>[];
  final middleFrames = <String>[];
  final mineFrames = <String>[];

  @override
  void onInit() {
    super.onInit();
    addLocationAssets();
    loadPage(global.tabIndex.value);
    global.tabIndex.listen(changeTabIndex);

    EventBusManager.share.listenAll((e) {
      if (e.type == AppEventType.login && e.data == "middle") {
        clickCenterBtn();
      }
    });
  }

  void addLocationAssets() {
    homeFrames.addAll(
      List.generate(
        20,
        (i) => 'assets/images/tabBar/home/${i.toString().padLeft(3, '0')}.png',
      ),
    );
    middleFrames.addAll(
      List.generate(
        12,
        (i) =>
            'assets/images/tabBar/center/${i.toString().padLeft(3, '0')}.png',
      ),
    );

    mineFrames.addAll(
      List.generate(
        14,
        (i) => 'assets/images/tabBar/mine/${i.toString().padLeft(3, '0')}.png',
      ),
    );
  }

  void changeTabIndex(int index) {
    //切换到 mine 页面
    if (index == 1) {
      _onMinePageEnter();
    }
    if (pages[index] == null) {
      loadPage(index);
    }
    global.tabIndex.value = index;
  }

  void _onMinePageEnter() {
    if (Get.isRegistered<MineLogic>()) {
      final mineLogic = Get.find<MineLogic>();
      mineLogic.updatePersonInfo();
    }
  }

  void loadPage(int index) {
    pages[index] ??= buildPage(index);
  }

  Widget buildPage(int index) {
    if (index == 0) {
      AppLogger.info('点击进入了HomePage页面');
      return HomePage();
    }
    AppLogger.info('点击进入了MinePage页面');
    return MinePage();
  }

  void clickCenterBtn() {
    if (!global.isLogin) {
      Get.toNamed(AppRoutes.appLogin, arguments: "middle");
      return;
    }

    SmartDialog.show(
      builder: (context) => const CreateCanvalsPage(),
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.centerFade_otherSlide,
      maskColor: Colors.black,
      maskWidget: null,
      clickMaskDismiss: true,
      keepSingle: true,
      permanent: false,
      animationTime: const Duration(milliseconds: 300),
      animationBuilder: (controller, child, animationParam) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}
