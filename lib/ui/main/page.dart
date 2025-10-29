import 'package:common/common.dart';
import 'package:flutter/material.dart';

import 'logic.dart';
import 'widgets/custom_bottom_navigation_bar.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(MainLogic());

    return CVirtualBack(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Obx(
          () => IndexedStack(
            index: logic.globalLogic.tabIndex.value,
            children: List.generate(2, (i) => logic.pages[i] ?? Container()),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(),
      ),
    );
  }
}
