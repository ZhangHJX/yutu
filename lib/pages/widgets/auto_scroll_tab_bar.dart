import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../model/index.dart';

class AutoScrollTabBar extends StatelessWidget {
  final List<TagModel> screenList;
  final TabController? tabController;
  final ValueChanged<int>? onTabTap;
  final double rightMargin;

  // text相关属性
  final String textColor;
  final String textSelectColor;
  final String itemBackColor;
  final String itemSelectBackColor;
  final Color backGroundColor;

  const AutoScrollTabBar({
    super.key,
    required this.screenList,
    this.tabController,
    this.onTabTap,
    this.rightMargin = 16,
    this.textColor = '#8D8D8D',
    this.textSelectColor = '#007BFE',
    this.itemBackColor = '#F4F4F4',
    this.itemSelectBackColor = '#D8F5FF',
    this.backGroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    // 如果列表为空或 TabController 未初始化，返回空容器
    if (screenList.isEmpty || tabController == null) {
      return SizedBox(height: 44.w);
    }
    return Container(
      height: 44.w,
      color: backGroundColor,
      margin: EdgeInsets.only(left: 16.w, right: rightMargin.w),
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
            unselectedLabelColor: '#8D8D8D'.color,
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
                  color: isSelected
                      ? itemSelectBackColor.color
                      : itemBackColor.color,
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Center(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: isSelected
                          ? textSelectColor.color
                          : textColor.color,
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
