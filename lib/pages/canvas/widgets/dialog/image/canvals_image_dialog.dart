import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'image_logic.dart';
import 'model/image_list_models.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/core/index.dart';

class CanvalsImageDialog extends StatefulWidget {
  final Function(List<PickerInfoModel> list)? onImageSelected;
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
    logic.onUploadSuccess = (List<PickerInfoModel> list) {
      if (widget.onImageSelected != null) {
        widget.onImageSelected!(list);
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
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      SmartDialog.dismiss();
                    },
                    child: SizedBox(
                      width: 45.w,
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
        child: SmartRefresher(
          key: logic.refresherKey,
          controller: logic.refreshController,
          enablePullDown: true,
          enablePullUp: logic.hasMore.value,
          header: ClassicHeader(height: 40),
          footer: ClassicFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
            completeDuration: Duration(milliseconds: 500),
          ),
          onRefresh: () async {
            await logic.onRefresh();
          },
          onLoading: () async {
            await logic.onLoad();
          },
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12.w,
              crossAxisSpacing: 14.w,
              childAspectRatio: 1.0, //宽高比为2
            ),
            itemCount: logic.imageList.length,
            itemBuilder: (context, index) {
              final model = logic.imageList[index];
              return _buildImageItem(model, index);
            },
          ),
        ),
      );
    });
  }

  /// 构建单个图片 item
  Widget _buildImageItem(ImageModel model, int index) {
    final bool isSelected = logic.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          // 再次点击同一个 item 时，支持取消选中
          if (logic.selectedIndex == index) {
            logic.selectedIndex = null;
          } else {
            logic.selectedIndex = index;
          }
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
              if (logic.global.connectStatus.currentStatus == Status.none) {
                showToast("确认失败");
                return;
              }
              if (!logic.global.isLogin) {
                SmartDialog.dismiss();
                Get.toNamed(AppRoutes.appLogin);
                return;
              }
              logic.selectedImageAction();
            },
          ),
        ],
      ),
    );
  }
}
