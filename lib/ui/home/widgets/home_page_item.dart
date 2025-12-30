import 'package:common/common.dart';
import 'package:flutter/material.dart';

class HomePageItem extends StatelessWidget {
  final double imageH;
  final String imageUrl;
  final String title;
  final String type;
  final int favorite;

  final VoidCallback onTap;
  final bool isSelected;
  final bool showCheck;

  const HomePageItem({
    super.key,
    required this.imageH,
    required this.imageUrl,
    required this.title,
    required this.type,
    required this.favorite,
    required this.onTap,
    this.showCheck = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // final itemWidth = (ScreenTools.screenWidth - 30.w - 9.w) / 2;
    // final itemHeight = calculateAspectRatio(itemWidth, item.canvasSize ?? '');
    // '${item.originalImage}${item.thumbnail}'

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.w),
      child: Stack(
        children: [
          Column(
            children: [
              // 上半部分可以换成你的缩略图
              SizedBox(
                height: imageH,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w600,
                          color: "#051E34".color,
                        ),
                      ),

                      if (showCheck)
                        Image.asset(
                          isSelected
                              ? "assets/images/mine/app_resource_select.png"
                              : "assets/images/mine/app_resource_unselect.png",
                          width: 18.w,
                          height: 18.w,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),

                  SizedBox(height: 4.w),

                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w),
                        decoration: BoxDecoration(
                          color: "#DCEDFE".color,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12.w,
                            color: "#007BFE".color,
                          ),
                        ),
                      ),

                      Spacer(),

                      CButton(
                        height: 22.w,
                        textColor: Colors.white,
                        text: Text(
                          '$favorite',
                          style: TextStyle(
                            fontSize: 12.w,
                            color: "#A7AFBD".color,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        spacing: 4.w,
                        icon: Image.asset(
                          "assets/images/mine/app_design_like.png",
                          width: 13.w,
                          height: 10.w,
                          fit: BoxFit.cover,
                        ),
                        onPressed: onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
