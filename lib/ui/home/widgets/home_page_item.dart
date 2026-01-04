import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/app/routes/index.dart';

class HomePageItem extends StatelessWidget {
  final int id;
  final double imageH;
  final String imageUrl;
  final String title;
  final int type;
  final int favorite;
  final bool isFavorite;
  final bool showCheck;

  const HomePageItem({
    super.key,
    required this.id,
    required this.imageH,
    required this.imageUrl,
    required this.title,
    required this.type,
    required this.favorite,
    this.showCheck = false,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Get.toNamed(AppRoutes.middle, arguments: {'id': id, "type": "home"}),
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

            Positioned(
              top: 6.w,
              right: 6.w,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint("=====GestureDetector===========");
                },
                child: SizedBox(
                  width: 35.w,
                  height: 35.w,
                  child: Center(
                    child: Image.asset(
                      isFavorite
                          ? "assets/images/home/home_collectin_btn_finsh.png"
                          : "assets/images/home/home_collectin_btn.png",
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
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
                      title,
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
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w),
                          decoration: BoxDecoration(
                            color: "#DCEDFE".color,
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Text(
                            type == 1 ? '官方' : '个人',
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
                            "assets/images/home/${isFavorite ? 'collection_favorite' : 'collection_no_favorite'}.png",
                            width: 14.w,
                            height: 14.w,
                            fit: BoxFit.cover,
                          ),
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
