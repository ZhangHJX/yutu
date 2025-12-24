import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'image_logic.dart';
import 'model/image_list_models.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'manager/canvals_image_manager.dart';

class CanvalsImageDialog extends StatefulWidget {
  final Function(String imageUrl, double? width, double? height)?
  onImageSelected;
  final BuildContext currentContext;
  const CanvalsImageDialog(
    this.currentContext, {
    super.key,
    this.onImageSelected,
  });
  @override
  State<CanvalsImageDialog> createState() => _CanvalsImageDialogState();
}

class _CanvalsImageDialogState extends State<CanvalsImageDialog> {
  final logic = Get.put(ImageLogic(), tag: imageDialog);

  /// 当前选中的素材索引（单选）
  int? _selectedIndex;
  late EasyRefreshController _controller;

  @override
  void dispose() {
    _controller.dispose();
    if (Get.isRegistered<ImageLogic>(tag: imageDialog)) {
      Get.delete<ImageLogic>(tag: imageDialog, force: true);
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    logic.onUploadSuccess = (String imagePath, double width, double height) {
      if (widget.onImageSelected != null) {
        widget.onImageSelected!(imagePath, width, height);
      }
      SmartDialog.dismiss();
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 372.w + ScreenTools.bottomBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.w),
          topRight: Radius.circular(24.w),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.only(top: 19.w, bottom: 9.w),
            height: 49.w,
            width: ScreenTools.screenWidth,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '上传素材',
                    style: TextStyle(
                      fontSize: 18.w,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff262626),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      SmartDialog.dismiss();
                    },
                    child: SizedBox(
                      width: 30.w,
                      height: 30.w,
                      child: Center(
                        child: Image.asset(
                          'assets/images/canvals/canvals_close_icon.png',
                          width: 12.w,
                          height: 12.w,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: ScreenTools.screenWidth,
            padding: EdgeInsets.symmetric(horizontal: 19.w),
            child: Text(
              "我的素材",
              style: TextStyle(
                fontSize: 13.w,
                fontWeight: FontWeight.w500,
                color: "#3E3E3E".color.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.left,
            ),
          ),

          Expanded(child: _buildListMaterial()),
          // 按钮区域
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  Widget _buildListMaterial() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.only(
          top: 8.w,
          bottom: 5.w,
          left: 19.w,
          right: 19.w,
        ),
        height: 231.w,
        child: EasyRefresh(
          clipBehavior: Clip.none,
          controller: _controller,
          header: ClassicHeader(
            showMessage: false,
            triggerWhenReach: true,
            dragText: '松开刷新',
            readyText: '记载中...',
            processingText: '记载中...',
            processedText: '刷新完成',
          ),
          footer: ClassicFooter(
            showMessage: false,
            triggerWhenReach: true,
            dragText: '上拉加载',
            processingText: '加载中...',
            processedText: '加载完成',
            noMoreText: '没有更多了',
          ),

          onRefresh: () async {
            await logic.onRefresh();
          },
          onLoad: logic.hasMore.value
              ? () async {
                  await logic.onLoad();
                }
              : null,
          child: Obx(() {
            final list = logic.imageList;

            return MasonryGridView.count(
              crossAxisCount: 3, // 两列瀑布流
              mainAxisSpacing: 12.w,
              crossAxisSpacing: 9.w,
              padding: EdgeInsets.zero,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final model = list[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // 根据模型中的原始宽高比例，计算当前 item 的高度
                    final originWidth = double.tryParse(model.width) ?? 1;
                    final originHeight = double.tryParse(model.height) ?? 1;
                    final safeWidth = originWidth <= 0 ? 1 : originWidth;
                    final safeHeight = originHeight <= 0 ? 1 : originHeight;
                    final itemWidth = constraints.maxWidth;
                    final ratio = safeHeight / safeWidth; // 高 / 宽
                    final itemHeight = itemWidth * ratio;
                    return SizedBox(
                      height: itemHeight,
                      child: _buildImageItem(model, index),
                    );
                  },
                );
              },
            );
          }),
        ),
      );
    });
  }

  /// 构建单个图片 item
  Widget _buildImageItem(ImageModel model, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // 更新单选选中状态
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.w),
          color: "#F5F5F5".color,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 图片
              CachedNetworkImage(
                imageUrl: model.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: "#F5F5F5".color,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: "#9082FF".color,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: "#F5F5F5".color,
                  child: Icon(
                    Icons.broken_image,
                    color: "#CCCCCC".color,
                    size: 24.w,
                  ),
                ),
              ),

              // 选中状态（如果后续有选中逻辑，可以在这里控制显示）
              if (isSelected)
                Positioned(
                  right: 4.w,
                  top: 6.w,
                  child: Image.asset(
                    'assets/images/canvals/image_item_select.png',
                    width: 16.w,
                    height: 16.w,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 27.w,
        right: 23.w,
        bottom: 16.w + ScreenTools.bottomBarHeight,
        top: 16.w,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              logic.pickerCanvalsImage(widget.currentContext);
            },
            child: SelectItemGradientBorder(
              isSelected: true,
              radius: 24.5.w,
              borderWidth: 1.w,
              backgroundColor: '#B8C4FF'.color,
              unselectedBorderColor: '#B8C4FF'.color,
              selectedGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ['#C86CFF'.color, '#5B98FF'.color],
              ),
              child: SizedBox(
                height: 45.w,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 26.w,
                    right: 28.w,
                    top: 12.w,
                    bottom: 12.w,
                  ),
                  child: Row(
                    children: [
                      // 替换按钮
                      Image.asset(
                        'assets/images/canvals/canval_picker_image.png',
                        width: 17.5.w,
                        height: 14.w,
                        fit: BoxFit.cover,
                      ),

                      SizedBox(width: 8.w),
                      Text(
                        "上传新图片",
                        style: TextStyle(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w500,
                          color: "#160D7E".color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          CButton(
            height: 45.w,
            width: 148.w,
            textColor: Colors.white,
            text: Text(
              '确认',
              style: TextStyle(
                fontSize: 14.w,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ['#C86CFF'.color, '#5B98FF'.color],
            ),
            borderRadius: 22.5.w,
            onPressed: () async {
              final index = _selectedIndex;
              final list = logic.imageList;

              if (index == null || index < 0 || index >= list.length) {
                showToast('请选择一张图片');
                return;
              }

              final model = list[index];
              final double width = double.tryParse(model.width) ?? 200.0;
              final double height = double.tryParse(model.height) ?? 200.0;

              try {
                showLoading('正在添加图片');

                // 统一由管理器处理“是否已下载 + 拷贝到 cavals/images”
                final String fileName = await CanvalsImageManager.instance
                    .ensureImageInCanvasImages(model.image);

                // 回调到外部，在画布中新增图片
                if (widget.onImageSelected != null) {
                  widget.onImageSelected!(fileName, width, height);
                }

                // 关闭当前图片选择弹窗
                SmartDialog.dismiss();
              } catch (e, stackTrace) {
                debugPrint('添加图片到画布失败: $e\n$stackTrace');
                showToast('添加图片失败，请稍后重试');
              } finally {
                SmartDialog.dismiss(status: SmartStatus.loading);
              }
            },
          ),
        ],
      ),
    );
  }
}
