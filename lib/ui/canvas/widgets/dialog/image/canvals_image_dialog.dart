import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'image_logic.dart';
import 'model/image_list_models.dart';
import 'package:voicetemplate/ui/widgets/index.dart';

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

  @override
  void dispose() {
    if (Get.isRegistered<ImageLogic>(tag: imageDialog)) {
      Get.delete<ImageLogic>(tag: imageDialog, force: true);
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
    return Container(
      padding: EdgeInsets.only(top: 8.w, bottom: 5.w, left: 19.w, right: 19.w),
      height: 231.w,
      child: Obx(() {
        return EasyRefresh(
          onRefresh: () async {
            await logic.onRefresh();
          },
          onLoad: () async {
            await logic.onLoad();
          },
          child: logic.imageList.isEmpty && !logic.isRefreshing.value
              ? Center(
                  child: Text(
                    '暂无素材',
                    style: TextStyle(fontSize: 14.w, color: "#999999".color),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.w,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 一排3个
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.w,
                    childAspectRatio: 1.0, // 正方形
                  ),
                  itemCount: logic.imageList.length,
                  itemBuilder: (context, index) {
                    // 加载更多指示器
                    if (index == logic.imageList.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: "#9082FF".color,
                          ),
                        ),
                      );
                    }
                    final model = logic.imageList[index];
                    return _buildImageItem(model);
                  },
                ),
        );
      }),
    );
  }

  /// 构建单个图片item
  Widget _buildImageItem(ImageModel model) {
    return GestureDetector(
      onTap: () {
        // 处理图片选择逻辑
        debugPrint('选中图片: ${model.image}');
        // 调用回调，将图片添加到画布
        if (widget.onImageSelected != null) {
          // widget.onImageSelected!(model.image, model.width, model.height);
          // 关闭对话框
          SmartDialog.dismiss();
        }
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

              //选中状态
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
