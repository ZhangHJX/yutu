import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/core/index.dart';
import 'package:voicetemplate/pages/model/index.dart';

class HomePageItem extends StatelessWidget {
  final CommonItemModel? model;
  final PageSource source;
  final VoidCallback favoriteCallBack;

  const HomePageItem({
    super.key,
    required this.model,
    required this.source,
    required this.favoriteCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final imageH = calculateAspectRatio(
      (ScreenTools.screenWidth - 30.w - 9.w) / 2,
      model?.canvasSize ?? '',
    );

    return GestureDetector(
      // behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed(
        AppRoutes.middle,
        arguments: {'id': model?.id, "type": source},
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.w),
        child: Stack(
          children: [
            Column(
              children: [
                // 上半部分可以换成你的缩略图
                SizedBox(
                  height: imageH,
                  child: CachedNetworkImage(
                    imageUrl: '${model?.originalImage}${model?.thumbnail}',
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
                ),
                Container(height: 47.w, color: Colors.white),
              ],
            ),

            /// 右上角：批量模式时显示勾选；非批量时可以显示删除图标
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 59.w,
                padding: EdgeInsets.only(left: 14.w, right: 14.w, top: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.w,
                        fontWeight: FontWeight.w600,
                        color: "#051E34".color,
                      ),
                    ),

                    SizedBox(height: 4.w),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w),
                          decoration: BoxDecoration(
                            color: "#DCEDFE".color,
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Text(
                            model?.isOfficial == 1 ? '官方' : '个人',
                            style: TextStyle(
                              fontSize: 12.w,
                              color: "#007BFE".color,
                            ),
                          ),
                        ),

                        CButton(
                          // backgroundColor: Colors.red,
                          height: 25.w,
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 5),
                          textColor: Colors.white,
                          text: Text(
                            '${model?.favoriteTotal}',
                            style: TextStyle(
                              fontSize: 12.w,
                              color: "#A7AFBD".color,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          spacing: 4.w,
                          icon: Image.asset(
                            "assets/images/home/${model?.isFavorite == 1 ? 'collection_selected' : 'collection_unselected'}.png",
                            width: 16.w,
                            height: 15.3.w,
                            fit: BoxFit.cover,
                          ),
                          onPressed: () => favoriteCallBack.call(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
