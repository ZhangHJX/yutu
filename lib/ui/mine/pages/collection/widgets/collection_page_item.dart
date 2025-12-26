import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../../model/design_model.dart';

class CollectionPageItem extends StatelessWidget {
  final DesignItemModel item;
  final bool isSelected;
  final bool showCheck;
  final VoidCallback onTap;

  const CollectionPageItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.showCheck,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = (ScreenTools.screenWidth - 30.w - 9.w) / 2;
    final itemHeight = calculateAspectRatio(
      itemWidth,
      item.canvasSize ?? '1:1',
    );
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.w),
        child: Stack(
          children: [
            Column(
              children: [
                // 上半部分可以换成你的缩略图
                SizedBox(
                  height: itemHeight,
                  child: CachedNetworkImage(
                    imageUrl: '${item.originalImage}${item.thumbnail}',
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
                          item.title ?? '',
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
                            "收藏",
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
                            '${item.favoriteTotal}',
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
                          onPressed: () {},
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
