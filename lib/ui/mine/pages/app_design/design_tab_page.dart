import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'design_logic.dart';
import 'widgets/desigin_page_item.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 可保活的 Tab 页面组件
class DesignTabPage extends StatefulWidget {
  final int tagId;
  final int tabIndex;
  const DesignTabPage({super.key, required this.tagId, required this.tabIndex});
  @override
  State<DesignTabPage> createState() => _DesignTabPageState();
}

class _DesignTabPageState extends State<DesignTabPage> {
  final logic = Get.find<AppDesiginLogic>();

  @override
  void initState() {
    super.initState();

    // 初始化该 tab 的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logic.initTabData(widget.tagId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabData = logic.getTabData(widget.tagId);
      if (tabData == null) {
        return Center(child: CircularProgressIndicator());
      }

      final designList = tabData.designList;
      final isLoading = tabData.isLoading.value;

      if (isLoading && designList.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }

      if (designList.isEmpty) {
        return Center(
          child: Text(
            '暂无数据',
            style: TextStyle(fontSize: 14.w, color: Colors.grey),
          ),
        );
      }

      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 9.w,
        padding: EdgeInsets.all(15.w),
        itemCount: designList.length,
        itemBuilder: (context, index) {
          final item = designList[index];
          final isSelected = logic.selectedIds.contains(item.uuid);
          return DesiginPageItem(
            item: item,
            isSelected: isSelected,
            showCheck: logic.isBatchMode.value,
            onTap: () {
              if (logic.isBatchMode.value) {
                logic.toggleItemSelection(item.uuid);
              } else {}
            },
          );
        },
      );
    });
  }
}
