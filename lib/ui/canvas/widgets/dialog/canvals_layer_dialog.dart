import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../controllers/canvals_controller.dart';
import '../../model/create_design_model.dart';
import '../../utils/gradient_border.dart';
import 'dart:io';

class CanvalsLayerDialog extends StatefulWidget {
  final CanvasProperties canvasProperties;
  final List<CanvasElement> layers;

  final Function(String) onLayerTap;
  final Function(String) onLayerDelete;
  final Function(int, int) onLayerReorder;
  final Function(String) onLayerToggleVisibility;
  final Function(String) onLayerLock;

  final VoidCallback onCanvalsLock;
  final VoidCallback onCanvalsActivie;

  const CanvalsLayerDialog({
    super.key,
    required this.canvasProperties,
    required this.layers,
    required this.onLayerTap,
    required this.onLayerDelete,
    required this.onLayerReorder,
    required this.onLayerToggleVisibility,
    required this.onLayerLock,
    required this.onCanvalsLock,
    required this.onCanvalsActivie,
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
      width: 163.w,
      height: 271.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.w), // 设置圆角半径
        boxShadow: [
          BoxShadow(
            color: "#CDE4FF".color,
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

          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverReorderableList(
                  onReorder: (oldIndex, newIndex) {
                    // 处理边界情况：当拖动到最底部时，newIndex 可能等于 itemCount
                    // 需要限制在有效范围内
                    final adjustedNewIndex = newIndex > widget.layers.length - 1
                        ? widget.layers.length - 1
                        : newIndex;

                    // 转换为实际数据中的索引（反转）
                    // 列表显示：顶部(index=0) -> 底部(index=layers.length-1)
                    // 数据存储：顶部(reversedIndex=0) -> 底部(reversedIndex=layers.length-1)
                    // 所以：reversedIndex = layers.length - 1 - displayIndex
                    final reversedOldIndex =
                        widget.layers.length - 1 - oldIndex;
                    final reversedNewIndex =
                        widget.layers.length - 1 - adjustedNewIndex;

                    // 边界检查：确保索引有效
                    if (reversedOldIndex < 0 ||
                        reversedOldIndex >= widget.layers.length ||
                        reversedNewIndex < 0 ||
                        reversedNewIndex >= widget.layers.length) {
                      return;
                    }

                    // 调用回调，传递实际数据中的索引
                    widget.onLayerReorder(reversedOldIndex, reversedNewIndex);
                  },
                  itemBuilder: (context, index) {
                    // 反转索引，让最上面的图层显示在列表顶部
                    final reversedIndex = widget.layers.length - 1 - index;
                    final layer = widget.layers[reversedIndex];

                    return _buildLayerItem(
                      key: ValueKey(layer.id),
                      layer: layer,
                      index: reversedIndex,
                      displayIndex: index,
                    );
                  },
                  itemCount: widget.layers.length,
                ),
                SliverToBoxAdapter(child: _buildLayerSuper()),
                SliverPadding(padding: EdgeInsets.only(bottom: 13.w)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem({
    required Key key,
    required CanvasElement layer,
    required int index,
    required int displayIndex, // SliverReorderableList 中的显示索引
  }) {
    // 根据元素类型获取名称
    String getLayerName() {
      switch (layer.type) {
        case ElementType.image:
          return '图片 ${index + 1}';
        case ElementType.rectangle:
        case ElementType.ellipse:
        case ElementType.line:
          return '形状 ${index + 1}';
        case ElementType.text:
          return layer.text;
      }
    }

    return ReorderableDelayedDragStartListener(
      key: key,
      index: displayIndex, // 使用显示索引，不是反转后的索引
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 13.w,
              color: Colors.white,
            ),

            // 使用 Obx 包裹需要响应选中状态变化的部分
            Obx(() {
              final isSelected = _controller.isSelected(layer.id);

              // 如果元素被选中，确保画布未选中（在下一帧更新，避免在 build 中直接修改状态）
              if (isSelected && widget.canvasProperties.isSelected) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      widget.canvasProperties.isSelected = false;
                    });
                  }
                });
              }

              return Row(
                children: [
                  SizedBox(width: 7.w),
                  // 拖拽手柄
                  Image.asset(
                    isSelected
                        ? 'assets/images/canvals/canvals_current_circle.png'
                        : 'assets/images/canvals/canvals_current_uncircle.png',
                    width: 3.w,
                    height: 12.w,
                    fit: BoxFit.fill,
                  ),

                  SizedBox(width: 7.w),

                  // 缩略图 - 传入isSelected参数
                  _getLayerThumbnail(layer, isSelected: isSelected),

                  // 图层信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.w),

                        // 名称和类型
                        Padding(
                          padding: EdgeInsets.only(left: 2.5.w),
                          child: Text(
                            getLayerName(),
                            style: TextStyle(
                              fontSize: 12.w,
                              fontWeight: FontWeight.w500,
                              color: "#FF3E3E3E".color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(height: 4.w),

                        // 底部：操作按钮栏
                        Container(
                          margin: EdgeInsets.only(left: 2.5.w, right: 8.w),
                          height: 23.w,
                          decoration: BoxDecoration(
                            color: "#DCEDFE".color.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // 切换可见性
                                  widget.onLayerToggleVisibility(layer.id);
                                },
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: 8.w,
                                    right: 5.w,
                                    top: 3.w,
                                    bottom: 4.w,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      layer.visible
                                          ? 'assets/images/canvals/canvals_layer_eye.png'
                                          : 'assets/images/canvals/canvals_layer_uneye.png',
                                      width: 16.w,
                                      height: 16.w,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),

                              // 画布图层不允许删除
                              GestureDetector(
                                onTap: () {
                                  widget.onLayerDelete(layer.id); // 删除图层
                                },
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: 5.w,
                                    right: 3.5.w,
                                    top: 4.w,
                                    bottom: 5.w,
                                  ),
                                  height: 23.w,
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/canvals/canvals_layer_delete.png',
                                      width: 14.w,
                                      height: 14.w,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),

                              GestureDetector(
                                onTap: () {
                                  widget.onLayerLock(layer.id); // 是否被锁
                                },
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: 3.5.w,
                                    right: 5.w,
                                    top: 2.w,
                                    bottom: 3.w,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      layer.isLock
                                          ? 'assets/images/canvals/canvals_layer_lock.png'
                                          : 'assets/images/canvals/canvals_layer_unlock.png',
                                      width: 18.w,
                                      height: 18.w,
                                      fit: BoxFit.fill,
                                    ),
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
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerSuper() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(width: double.infinity, height: 13.w, color: Colors.white),

          // 使用 Obx 包裹，响应元素选中状态变化
          Obx(() {
            // 检查是否有元素被选中
            final hasElementSelected = _controller.selectedId.isNotEmpty;

            // 如果元素被选中，确保画布未选中（在下一帧更新，避免在 build 中直接修改状态）
            if (hasElementSelected && widget.canvasProperties.isSelected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    widget.canvasProperties.isSelected = false;
                  });
                }
              });
            }

            return Row(
              children: [
                SizedBox(width: 7.w),
                // 拖拽手柄
                Image.asset(
                  widget.canvasProperties.isSelected
                      ? 'assets/images/canvals/canvals_current_circle.png'
                      : 'assets/images/canvals/canvals_current_uncircle.png',
                  width: 3.w,
                  height: 12.w,
                  fit: BoxFit.fill,
                ),

                SizedBox(width: 7.w),

                // 画布缩略图
                GestureDetector(
                  onTap: () {
                    widget.onCanvalsActivie();
                  },
                  child: GradientBorder(
                    borderWidth: widget.canvasProperties.isSelected ? 1.5 : 0,
                    gradientColors: [Color(0xFFC86CFF), Color(0xFF5B98FF)],
                    borderRadius: BorderRadius.circular(12.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.w),
                      child: Container(
                        width: 54.w,
                        height: 54.w,
                        color: "#EAF4FE".color,
                        child: Center(
                          child: Container(
                            width: 36.w,
                            height: 28.w,
                            color: '#D8D8D8'.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 图层信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.w),
                      Padding(
                        padding: EdgeInsets.only(left: 2.5.w),
                        child: Text(
                          "画布",
                          style: TextStyle(
                            fontSize: 12.w,
                            fontWeight: FontWeight.w500,
                            color: "#FF3E3E3E".color,
                          ),
                        ),
                      ),

                      SizedBox(height: 4.w),

                      Container(
                        margin: EdgeInsets.only(left: 2.5.w, right: 8.w),
                        height: 23.w,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: "#DCEDFE".color.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                widget.onCanvalsLock();
                              },
                              child: SizedBox(
                                height: 23.w,
                                width: 28.w,
                                child: Center(
                                  child: Image.asset(
                                    widget.canvasProperties.isLock
                                        ? 'assets/images/canvals/canvals_layer_lock.png'
                                        : 'assets/images/canvals/canvals_layer_unlock.png',
                                    width: 18.w,
                                    height: 18.w,
                                    fit: BoxFit.fill,
                                  ),
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
            );
          }),
        ],
      ),
    );
  }

  Widget _getLayerThumbnail(CanvasElement layer, {required bool isSelected}) {
    Widget content;

    switch (layer.type) {
      case ElementType.image:
        content = Image.file(File(layer.imagePath), fit: BoxFit.cover);
        break;
      case ElementType.rectangle:
        content = Center(
          child: Container(width: 36.w, height: 28.w, color: '#D8D8D8'.color),
        );
        break;
      case ElementType.ellipse:
        content = Center(
          child: Container(
            width: 36.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: '#D8D8D8'.color, // 填充色
              borderRadius: BorderRadius.all(Radius.elliptical(18.w, 14.w)),
            ),
          ),
        );
        break;
      case ElementType.line:
        content = Center(
          child: Container(width: 36.w, height: 2.w, color: '#D8D8D8'.color),
        );
        break;
      case ElementType.text:
        content = Center(
          child: Text(
            layer.text.isNotEmpty
                ? (layer.text.length >= 2
                      ? layer.text.substring(0, 2)
                      : layer.text)
                : '文本',
            style: TextStyle(
              fontSize: 12.w,
              fontWeight: FontWeight.w500,
              color: "#3E3E3E".color,
            ),
          ),
        );
        break;
    }

    // 返回带圆角裁剪的内容
    return GestureDetector(
      onTap: () {
        // 点击元素项：选中元素，取消画布选中
        setState(() {
          widget.canvasProperties.isSelected = false;
        });
        // 调用原有的图层点击回调
        widget.onLayerTap(layer.id);
      },
      child: GradientBorder(
        borderWidth: isSelected ? 1.5 : 0,
        gradientColors: [Color(0xFFC86CFF), Color(0xFF5B98FF)],
        borderRadius: BorderRadius.circular(12.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.w),
          child: Container(
            width: 54.w,
            height: 54.w,
            color: "#EAF4FE".color,
            child: content,
          ),
        ),
      ),
    );
  }
}
