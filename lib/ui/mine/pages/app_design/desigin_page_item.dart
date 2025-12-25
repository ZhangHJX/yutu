import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/design_model.dart';

class DesiginPageItem extends StatelessWidget {
  final DesignItemModel item;
  final bool isSelected;
  final bool showCheck;
  final VoidCallback onTap;

  const DesiginPageItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.showCheck,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.w),
        child: Stack(
          children: [
            Column(
              children: [
                // 上半部分可以换成你的缩略图
                Container(height: 140, color: Colors.red),
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
                          item.title,
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
                            "设计",
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
                            fit: BoxFit.fill,
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
