import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../controllers/canvals_controller.dart';
import '../../controllers/create_design_model.dart';
import '../../../widgets/gradient_border.dart';

class CanvalsLayerDialog extends StatefulWidget {
  final List<EditBoxData> layers;
  final Function(String) onLayerTap;
  final Function(String) onLayerDelete;
  final Function(int, int) onLayerReorder;
  final double height;
  final double width;

  const CanvalsLayerDialog({
    super.key,
    required this.layers,
    required this.onLayerTap,
    required this.onLayerDelete,
    required this.onLayerReorder,
    required this.height,
    required this.width,
  });

  @override
  State<CanvalsLayerDialog> createState() => _CanvalsLayerDialogState();
}

class _CanvalsLayerDialogState extends State<CanvalsLayerDialog> {
  late CanvalsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CanvalsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height, // 使用传入的高度或默认高度
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.w), // 设置圆角半径
        boxShadow: [
          BoxShadow(
            color: Color(0xFFCDE4FF),
            blurRadius: 5.w,
            offset: Offset(0, 1.w),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.only(left: 15.w, top: 8.w),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/canvals/canvals_tuodong_icon.png',
                  width: 9.w,
                  height: 8.w,
                  fit: BoxFit.fill,
                ),

                SizedBox(width: 2.w),

                Expanded(
                  child: Text(
                    '长按拖动调整图层位置',
                    style: TextStyle(
                      fontSize: 12.w,
                      color: Color(0xFF4986FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 图层列表
          Expanded(
            child: ReorderableListView.builder(
              itemCount: widget.layers.length,
              onReorder: (oldIndex, newIndex) {
                // 处理拖拽重排序，需要反转索引
                final reversedOldIndex = widget.layers.length - 1 - oldIndex;
                final reversedNewIndex = widget.layers.length - 1 - newIndex;
                widget.onLayerReorder(reversedOldIndex, reversedNewIndex);
              },
              itemBuilder: (context, index) {
                // 反转索引，让最上面的图层显示在列表顶部
                final reversedIndex = widget.layers.length - 1 - index;
                final layer = widget.layers[reversedIndex];
                final isSelected = _controller.isSelected(layer.id);

                return _buildLayerItem(
                  key: ValueKey(layer.id),
                  layer: layer,
                  index: reversedIndex,
                  isSelected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem({
    required Key key,
    required EditBoxData layer,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      key: key,
      child: Column(
        children: [
          Container(width: double.infinity, height: 13.w, color: Colors.white),
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Row(
              children: [
                // 拖拽手柄
                Padding(
                  padding: EdgeInsets.only(left: 7.w),
                  child: Image.asset(
                    'assets/images/canvals/canvals_current_circle.png',
                    width: 3.w,
                    height: 12.w,
                    fit: BoxFit.fill,
                  ),
                ),

                // 缩略图
                _buildLayerThumbnail(layer),

                // 图层信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 名称和类型
                      Padding(
                        padding: EdgeInsets.only(left: 9.w),
                        child: Column(
                          children: [
                            Text(
                              "图片1",
                              style: TextStyle(
                                fontSize: 12.w,
                                fontWeight: FontWeight.w500,
                                color: "#FF3E3E3E".color,
                              ),
                            ),

                            Text(
                              "image",
                              style: TextStyle(
                                fontSize: 12.w,
                                color: "#FF9E9E9E".color,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 底部：操作按钮栏
                      Padding(
                        padding: EdgeInsets.only(left: 4.w, right: 17.w),
                        child: Container(
                          decoration: BoxDecoration(
                            color: "#FFDCEDFE".color.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: 8.w, right: 5.w),
                                height: 23.w,
                                child: Icon(
                                  Icons.visibility_outlined,
                                  size: 16.w,
                                  color: Colors.grey[700],
                                ),
                              ),

                              SizedBox(width: 5.w),

                              Container(
                                padding: EdgeInsets.only(
                                  left: 6.w,
                                  right: 8.w,
                                  top: 4.w,
                                  bottom: 5.w,
                                ),
                                height: 23.w,
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 14.w,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerThumbnail(EditBoxData layer) {
    return Padding(
      padding: EdgeInsets.only(left: 5.5.w),
      child: GradientBorder(
        gradientColors: true ? [Color(0xFFC86CFF), Color(0xFF5B98FF)] : [],
        borderRadius: BorderRadius.circular(12.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.w),
          child: Container(width: 54.w, height: 54.w, color: Colors.red),
        ),
      ),
    );
  }
}
