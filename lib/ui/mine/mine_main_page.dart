import 'dart:ui';
import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 代理人个人中心
class MineMainPage extends HookWidget {
  MineMainPage({super.key});

  // ProfileLogic get logic => Get.find();
  // GlobalLogic get globalLogic => Get.find();

  // final nestedKey = GlobalKey<ExtendedNestedScrollViewState>();
  final topContentKey = GlobalKey();
  final fixedNavKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isManualTabChange = useState(false);

    // final tabController = useTabController(
    //   initialLength: 2,
    //   initialIndex: logic.currentModuleTab.value,
    // );

    /// 是否显示分组部分
    final showProfileTab = useState(false);

    /// 顶部内容是否大于要偏移部分
    final isLarge = useState(false);

    final opacity = useState<double>(0);

    /// 分组部分top
    final profileTop = useState<double>(0);

    /// 公共顶部部分的高度
    final topContentH = useState<double>(0);

    /// 需要偏移的量
    final totalOffsetY = useState<double>(0);

    /// 顶部固定栏的高度
    final fixedNavBottom = useState<double>(0);

    // useEffect(() {
    //   Future.delayed(Duration(milliseconds: 300), () {
    //     final topContent =
    //         topContentKey.currentContext?.findRenderObject() as RenderBox;
    //     topContentH.value = topContent.size.height;
    //     isLarge.value = topContentH.value > totalOffsetY.value;

    //     final fixedNav =
    //         fixedNavKey.currentContext?.findRenderObject() as RenderBox;
    //     fixedNavBottom.value = fixedNav.size.height;
    //     profileTop.value = fixedNav.size.height;

    //     totalOffsetY.value = topContentH.value + 76.w - fixedNavBottom.value;
    //   });
    //   return null;
    // }, [topContentKey.currentContext, fixedNavKey.currentContext]);

    // 监听外部滚动控制器
    // useEffect(() {
    //   double currentY = 0;
    //   Future.delayed(Duration(milliseconds: 300), () {
    //     nestedKey.currentState?.outerController.addListener(() {
    //       final pixels =
    //           nestedKey.currentState?.outerController.position.pixels ?? 0.0;
    //       opacity.value = clampDouble(pixels / 40, 0, 1);

    //       if (isLarge.value) {
    //         showProfileTab.value = pixels >= totalOffsetY.value;
    //         profileTop.value =
    //             fixedNavBottom.value + pixels - topContentH.value;
    //       }

    //       currentY = pixels;
    //     });

    //     nestedKey.currentState?.innerController.addListener(() {
    //       if (currentY <= totalOffsetY.value) {
    //         final pixels =
    //             nestedKey.currentState?.innerController.position.pixels ?? 0.0;
    //         showProfileTab.value = pixels + currentY >= totalOffsetY.value;
    //       }
    //     });
    //   });
    //   return null;
    // }, [nestedKey.currentState]);

    // // 监听tab点击
    // final currentTab = useStream(logic.currentModuleTab.stream);
    // useEffect(() {
    //   if (currentTab.hasData && currentTab.data != null) {
    //     isManualTabChange.value = true;

    //     // 先执行tab切换动画
    //     tabController.animateTo(currentTab.data!);

    //     Future.delayed(Duration(milliseconds: 300), () {
    //       if (nestedKey.currentState?.outerController.hasClients ?? false) {
    //         nestedKey.currentState?.outerController.animateTo(
    //           0,
    //           duration: Duration(milliseconds: 300),
    //           curve: Curves.easeInOut,
    //         );
    //       }
    //     });
    //   }

    //   return null;
    // }, [currentTab.data, nestedKey.currentState?.outerController.hasClients]);

    // 监听tab切换
    // useEffect(() {
    //   void listener() {
    //     if (isManualTabChange.value) {
    //       isManualTabChange.value = false;
    //       return;
    //     }

    //     final value = tabController.animation!.value;
    //     final index = value.round();
    //     if ((value - index).abs() < 0.1) {
    //       logic.changeModuleTab(index);
    //     }
    //   }

    //   tabController.animation!.addListener(listener);
    //   return () => tabController.animation!.removeListener(listener);
    // }, []);

    return Text("我的页面");
  }
}

/// 代理人个人中心的页面
// // class _RightTabContent extends StatelessWidget {
//   const _RightTabContent({required this.showProfileTab, required this.top});
//   final bool showProfileTab;
//   final double top;

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: AlignmentDirectional.topCenter,
//       children: [
//         CustomScrollView(
//           physics: ClampingScrollPhysics(),
//           slivers: [
//             SliverToBoxAdapter(
//               child: Container(
//                 padding: EdgeInsets.only(bottom: 9.w, left: 12.w, right: 12.w),
//                 color: Colors.white,
//                 child: ScrollableEntries(),
//               ),
//             ),
//             SliverToBoxAdapter(child: FixedScrollableWidget()),
//             SliverPadding(
//               padding: EdgeInsets.symmetric(horizontal: 12.w),
//               sliver: SliverMasonryGrid(
//                 // crossAxisSpacing: 7.w,
//                 mainAxisSpacing: 8.w,
//                 gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 1,
//                 ),
//                 delegate: SliverChildBuilderDelegate((_, idx) {
//                   // return ProfileDynamic(isVideo: idx.isEven);
//                   return ServiceItemCell(
//                     item: ServiceItemModel(
//                       cover: '',
//                       coverSmall: '',
//                       id: '',
//                       labelId: '',
//                       labelName: '',
//                       name: '',
//                       platformType: 1,
//                       tag: '',
//                     ),
//                   );
//                 }, childCount: 10),
//               ),
//             ),
//           ],
//         ),
//         if (showProfileTab)
//           Positioned.fill(
//             bottom: null,
//             top: top,
//             child: FixedScrollableWidget(),
//           ),
//       ],
//     );
//   }
// }
