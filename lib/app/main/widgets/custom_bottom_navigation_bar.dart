import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../logic.dart';
import 'custom_tab_bar.dart';
import 'tab_bar_item.dart';
import 'center_tab_bar_button.dart';
import 'package:voicetemplate/ui/canvas/pages/create/create_canvals_page.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<MainLogic>(
      builder: (logic) {
        final currentIndex = logic.globalLogic.tabIndex.value;
        debugPrint('currentIndex:$currentIndex');
        return CustomTabBarWithCenter(
          currentIndex: currentIndex,
          onTap: (index) {
            debugPrint('CustomTabBarWithCenter:$index');
            logic.globalLogic.tabIndex.value = index;
          },
          items: [
            TabBarItem(
              normalPath: 'assets/images/tabBar/home_bar_icon_unselect.png',
              selectePath: 'assets/images/tabBar/home_bar_icon_select.png',
              label: '首页',
              width: 37,
              height: 37,
              selectedFrames: logic.homeFrames,
              frameDuration: const Duration(milliseconds: 50),
            ),
            TabBarItem(
              normalPath: 'assets/images/tabBar/mine_bar_icon_unselect.png',
              selectePath: 'assets/images/tabBar/mine_bar_icon_select.png',
              label: '我的',
              width: 37,
              height: 37,
              selectedFrames: logic.mineFrames,
              frameDuration: const Duration(milliseconds: 50),
            ),
          ],
          centerButton: CenterTabBarButton(
            item: TabBarItem(
              normalPath: 'assets/images/tabBar/middle_bar_icon.png',
              selectePath: 'assets/images/tabBar/middle_bar_icon.png',
              label: '我的',
              width: 37,
              height: 37,
              selectedFrames: logic.middleFrames,
              frameDuration: const Duration(milliseconds: 50),
            ),
            size: 70,
            onTap: () {
              _showCreateDesignDialog();
            },
          ),
        );
      },
    );
  }

  void _showCreateDesignDialog() {
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
