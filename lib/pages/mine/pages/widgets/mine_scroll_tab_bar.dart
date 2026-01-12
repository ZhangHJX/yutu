import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/pages/model/index.dart';

class MineScrollTabBar extends StatelessWidget {
  final List<ScreenItemModel> screenList;
  final TabController? tabController;
  final ValueChanged<int>? onTabTap;

  const MineScrollTabBar({
    super.key,
    required this.screenList,
    this.tabController,
    this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    // 如果列表为空或 TabController 未初始化，返回空容器
    if (screenList.isEmpty || tabController == null) {
      return SizedBox(height: 44.w);
    }
    return Container(
      height: 44.w,
      color: Colors.transparent,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: AnimatedBuilder(
        animation: tabController!,
        builder: (context, child) {
          return TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start, // ⭐ 防止某些场景默认不是start
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            labelColor: '#007BFE'.color,
            unselectedLabelColor: '#2A6181'.color,
            labelStyle: TextStyle(fontSize: 14.w, fontWeight: FontWeight.w400),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.w,
              fontWeight: FontWeight.w400,
            ),
            onTap: onTabTap,
            tabs: List.generate(screenList.length, (index) {
              final item = screenList[index];
              final isSelected = tabController!.index == index;
              return Container(
                margin: EdgeInsets.only(
                  right: _paddingWithTab(index, screenList.length - 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 9.w),
                height: 24.w,
                decoration: BoxDecoration(
                  color: isSelected ? '#DCEDFE'.color : '#E9F2F7'.color,
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Center(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: isSelected ? '#007BFE'.color : '#2A6181'.color,
                      fontSize: 14.w,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _paddingWithTab(int index, int total) {
    if (index < total) {
      return 12.w;
    }
    return 0;
  }
}
