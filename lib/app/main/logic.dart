import 'package:common/common.dart';
import 'package:flutter/material.dart';

import 'package:voicetemplate/stores/global.dart';
import '../../ui/home/page.dart';
import '../../ui/mine/mine_main_page.dart';

class MainLogic extends GetxController {
  final globalLogic = Get.put(GlobalLogic(), permanent: true);

  final pages = List<Widget?>.filled(2, null).obs;

  @override
  void onInit() {
    super.onInit();

    loadPage(globalLogic.tabIndex.value);

    globalLogic.tabIndex.listen(changeTabIndex);
  }

  void changeTabIndex(int index) {
    debugPrint('changeTabIndex:$index');
    if (pages[index] == null) {
      loadPage(index);
    }
    globalLogic.tabIndex.value = index;
  }

  void loadPage(int index) {
    pages[index] ??= buildPage(index);
  }

  Widget buildPage(int index) {
    if (index == 0) {
      debugPrint("HomePage-------");
      return HomePage();
    }

    debugPrint("MinePage-------");
    return MinePage();
  }
}
